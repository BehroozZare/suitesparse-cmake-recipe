/**
 * CHOLMOD Demo - Test integration of CHOLMOD sparse Cholesky factorization
 * 
 * This demo reads a sparse symmetric positive-definite matrix from a Matrix Market file,
 * performs Cholesky factorization, solves a linear system Ax = b, and computes the residual.
 */

#include <iostream>
#include <fstream>
#include <sstream>
#include <vector>
#include <algorithm>
#include <cmath>
#include <cholmod.h>

// Structure to hold a COO triplet
struct Triplet {
    int row;
    int col;
    double val;
};

/**
 * Read a Matrix Market file in coordinate format
 * Returns true on success, false on failure
 */
bool read_matrix_market(const char* filename, int& n, int& m, std::vector<Triplet>& triplets) {
    std::ifstream file(filename);
    if (!file.is_open()) {
        std::cerr << "Error: Cannot open file " << filename << std::endl;
        return false;
    }

    std::string line;
    
    // Skip comments (lines starting with %)
    while (std::getline(file, line)) {
        if (line.empty() || line[0] == '%') continue;
        break;
    }
    
    // Parse header: rows cols nnz
    int nnz;
    std::istringstream header(line);
    header >> n >> m >> nnz;
    
    if (n != m) {
        std::cerr << "Error: Matrix must be square (got " << n << "x" << m << ")" << std::endl;
        return false;
    }
    
    std::cout << "Reading matrix: " << n << "x" << m << " with " << nnz << " entries" << std::endl;
    
    // Read triplets
    triplets.reserve(nnz);
    int row, col;
    double val;
    
    while (file >> row >> col >> val) {
        // Convert from 1-based to 0-based indexing
        triplets.push_back({row - 1, col - 1, val});
    }
    
    file.close();
    
    std::cout << "Read " << triplets.size() << " entries from file" << std::endl;
    return true;
}

int main(int argc, char** argv) {
    std::cout << "=== CHOLMOD Integration Test ===" << std::endl;
    std::cout << std::endl;

    // Get matrix filename from command line or use default
    const char* filename = (argc > 1) ? argv[1] : "data/matrix.mtx";

    // Initialize CHOLMOD
    cholmod_common c;
    cholmod_start(&c);

    // Print CHOLMOD version info
    int version[3];
    cholmod_version(version);
    std::cout << "CHOLMOD version: " << version[0] << "." << version[1] << "." << version[2] << std::endl;
    std::cout << std::endl;

    // Read matrix from file
    int n, m;
    std::vector<Triplet> all_triplets;
    if (!read_matrix_market(filename, n, m, all_triplets)) {
        cholmod_finish(&c);
        return 1;
    }

    // Extract lower triangular entries (row >= col) for symmetric storage
    std::vector<Triplet> lower_triplets;
    for (const auto& t : all_triplets) {
        if (t.row >= t.col) {
            lower_triplets.push_back(t);
        }
    }
    std::cout << "Lower triangular entries: " << lower_triplets.size() << std::endl;

    // Create CHOLMOD triplet matrix (easier than direct CSC manipulation)
    size_t nnz = lower_triplets.size();
    cholmod_triplet* T = cholmod_allocate_triplet(
        n,              // nrow
        n,              // ncol
        nnz,            // nzmax
        -1,             // stype: -1 = lower triangular stored (symmetric)
        CHOLMOD_REAL,   // xtype
        &c
    );

    if (T == nullptr) {
        std::cerr << "Error: Failed to allocate CHOLMOD triplet matrix" << std::endl;
        cholmod_finish(&c);
        return 1;
    }

    // Fill triplet matrix - use the correct integer type based on CHOLMOD's itype
    int* Ti = static_cast<int*>(T->i);
    int* Tj = static_cast<int*>(T->j);
    double* Tx = static_cast<double*>(T->x);
    
    for (size_t k = 0; k < nnz; k++) {
        Ti[k] = lower_triplets[k].row;
        Tj[k] = lower_triplets[k].col;
        Tx[k] = lower_triplets[k].val;
    }
    T->nnz = nnz;

    // Convert triplet to sparse CSC format
    cholmod_sparse* A = cholmod_triplet_to_sparse(T, nnz, &c);
    cholmod_free_triplet(&T, &c);

    if (A == nullptr) {
        std::cerr << "Error: Failed to convert triplet to sparse matrix" << std::endl;
        cholmod_finish(&c);
        return 1;
    }

    std::cout << "Created CHOLMOD sparse matrix A (" << n << "x" << n 
              << ", " << A->nzmax << " non-zeros in lower triangle)" << std::endl;

    // Create right-hand side vector b = [1, 2, 3, ..., n]
    cholmod_dense* b = cholmod_allocate_dense(n, 1, n, CHOLMOD_REAL, &c);
    double* b_ptr = static_cast<double*>(b->x);
    for (int i = 0; i < n; i++) {
        b_ptr[i] = static_cast<double>(i + 1);
    }

    // Analyze and factorize
    std::cout << std::endl << "Performing Cholesky factorization..." << std::endl;
    
    cholmod_factor* L = cholmod_analyze(A, &c);
    if (L == nullptr) {
        std::cerr << "ERROR: cholmod_analyze failed!" << std::endl;
        cholmod_free_dense(&b, &c);
        cholmod_free_sparse(&A, &c);
        cholmod_finish(&c);
        return 1;
    }
    
    int success = cholmod_factorize(A, L, &c);
    if (!success || c.status != CHOLMOD_OK) {
        std::cerr << "ERROR: cholmod_factorize failed! status = " << c.status << std::endl;
        cholmod_free_factor(&L, &c);
        cholmod_free_dense(&b, &c);
        cholmod_free_sparse(&A, &c);
        cholmod_finish(&c);
        return 1;
    }
    
    std::cout << "Factorization successful!" << std::endl;
    std::cout << "  - Factor nonzeros: " << L->nzmax << std::endl;

    // Solve Ax = b
    std::cout << std::endl << "Solving Ax = b..." << std::endl;
    cholmod_dense* x = cholmod_solve(CHOLMOD_A, L, b, &c);
    if (x == nullptr) {
        std::cerr << "ERROR: cholmod_solve failed!" << std::endl;
        cholmod_free_factor(&L, &c);
        cholmod_free_dense(&b, &c);
        cholmod_free_sparse(&A, &c);
        cholmod_finish(&c);
        return 1;
    }
    
    std::cout << "Solve completed." << std::endl;

    // Compute residual r = b - A*x
    // Since A is stored as lower triangular (stype=-1), it represents a symmetric matrix.
    // We manually compute A*x for the full symmetric matrix.
    std::cout << std::endl << "Computing residual..." << std::endl;
    
    double* x_ptr = static_cast<double*>(x->x);
    std::vector<double> Ax_result(n, 0.0);
    
    // Get CSC arrays from CHOLMOD sparse matrix
    int* Ap = static_cast<int*>(A->p);
    int* Ai = static_cast<int*>(A->i);
    double* Ax = static_cast<double*>(A->x);
    
    // Compute A*x for symmetric matrix stored in lower triangular CSC
    // For each column j, process entries A[i,j] where i >= j
    for (int j = 0; j < n; j++) {
        for (int k = Ap[j]; k < Ap[j + 1]; k++) {
            int i = Ai[k];
            double val = Ax[k];
            
            // A[i,j] * x[j] contributes to row i
            Ax_result[i] += val * x_ptr[j];
            
            // For off-diagonal entries (i != j), A[j,i] = A[i,j] contributes to row j
            if (i != j) {
                Ax_result[j] += val * x_ptr[i];
            }
        }
    }
    
    // Compute L2 norm of residual r = b - A*x
    double residual_norm = 0.0;
    for (int i = 0; i < n; i++) {
        double diff = b_ptr[i] - Ax_result[i];
        residual_norm += diff * diff;
    }
    residual_norm = std::sqrt(residual_norm);
    
    // Also compute norm of b for relative residual
    double b_norm = 0.0;
    for (int i = 0; i < n; i++) {
        b_norm += b_ptr[i] * b_ptr[i];
    }
    b_norm = std::sqrt(b_norm);
    
    double relative_residual = residual_norm / b_norm;
    
    std::cout << "Residual norm ||b - Ax|| = " << residual_norm << std::endl;
    std::cout << "Relative residual ||b - Ax|| / ||b|| = " << relative_residual << std::endl;
    
    if (relative_residual < 1e-10) {
        std::cout << std::endl << "SUCCESS: CHOLMOD integration test PASSED!" << std::endl;
    } else if (relative_residual < 1e-6) {
        std::cout << std::endl << "SUCCESS: Solution is acceptable (relative residual < 1e-6)" << std::endl;
    } else {
        std::cout << std::endl << "WARNING: Residual larger than expected" << std::endl;
    }

    // Cleanup
    cholmod_free_dense(&x, &c);
    cholmod_free_factor(&L, &c);
    cholmod_free_dense(&b, &c);
    cholmod_free_sparse(&A, &c);
    cholmod_finish(&c);

    std::cout << std::endl << "CHOLMOD resources freed. Done!" << std::endl;
    
    return 0;
}
