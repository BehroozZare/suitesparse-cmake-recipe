# SuiteSparse CMake Recipe

[![Build Linux](https://github.com/BehroozZare/suitesparse-cmake-recipe/actions/workflows/build.yml/badge.svg?branch=main&event=push&job=ubuntu-latest)](https://github.com/BehroozZare/suitesparse-cmake-recipe/actions/workflows/build.yml)
[![Build macOS](https://github.com/BehroozZare/suitesparse-cmake-recipe/actions/workflows/build.yml/badge.svg?branch=main&event=push&job=macos-latest)](https://github.com/BehroozZare/suitesparse-cmake-recipe/actions/workflows/build.yml)
[![Build Windows](https://github.com/BehroozZare/suitesparse-cmake-recipe/actions/workflows/build.yml/badge.svg?branch=main&event=push&job=windows-latest)](https://github.com/BehroozZare/suitesparse-cmake-recipe/actions/workflows/build.yml)
[![Tests](https://github.com/BehroozZare/suitesparse-cmake-recipe/actions/workflows/test.yml/badge.svg)](https://github.com/BehroozZare/suitesparse-cmake-recipe/actions/workflows/test.yml)

A minimal, cross-platform CMake recipe for integrating [SuiteSparse](https://github.com/DrTimothyAldenDavis/SuiteSparse) (specifically CHOLMOD) into your C++ projects using `FetchContent`. No system-wide installation required.

## Features

- **Zero Dependencies**: Automatically downloads and builds SuiteSparse v7.11.0 and METIS
- **Cross-Platform**: Works on Linux, macOS, and Windows
- **Minimal Build**: Only builds required SuiteSparse components (CHOLMOD, AMD, CAMD, COLAMD, CCOLAMD)
- **Static Linking**: Produces self-contained executables
- **Modern CMake**: Uses `FetchContent` for dependency management

## Quick Start

### Prerequisites

- CMake ≥ 3.18
- C/C++ compiler with C++20 support
- BLAS/LAPACK (system-provided)
- OpenMP (optional, for parallelization)

**Linux (Ubuntu/Debian):**
```bash
sudo apt-get install build-essential cmake libomp-dev
```

**macOS:**
```bash
brew install cmake libomp
```

**Windows:**
- Visual Studio 2022 with C++ workload
- CMake (bundled with VS or standalone)
- OpenBLAS (see Windows build instructions below)

### Build

**Linux/macOS:**
```bash
# Clone the repository
git clone https://github.com/BehroozZare/suitesparse-cmake-recipe.git
cd suitesparse-cmake-recipe

# Configure and build
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release --parallel

# Run the demo
./build/cholmod_demo data/matrix.mtx
```

**Windows (PowerShell):**
```powershell
# Clone the repository
git clone https://github.com/BehroozZare/suitesparse-cmake-recipe.git
cd suitesparse-cmake-recipe

# Download and extract OpenBLAS
$OpenBLAS_VERSION = "0.3.28"
$OpenBLAS_URL = "https://github.com/OpenMathLib/OpenBLAS/releases/download/v${OpenBLAS_VERSION}/OpenBLAS-${OpenBLAS_VERSION}-x64.zip"
$OpenBLAS_DIR = "C:\OpenBLAS"

Invoke-WebRequest -Uri $OpenBLAS_URL -OutFile openblas.zip
Expand-Archive -Path openblas.zip -DestinationPath $OpenBLAS_DIR -Force

# Move contents from versioned subdirectory to parent
$SubDir = Get-ChildItem -Path $OpenBLAS_DIR -Directory | Select-Object -First 1
if ($SubDir) {
  Move-Item -Path "$($SubDir.FullName)\*" -Destination $OpenBLAS_DIR -Force
  Remove-Item -Path $SubDir.FullName -Force -Recurse
}

# Set paths (adjust if your OpenBLAS structure differs)
$OPENBLAS_LIB = (Get-ChildItem -Path $OpenBLAS_DIR -Recurse -Filter "*openblas*.lib" | Select-Object -First 1).FullName
$OPENBLAS_INCLUDE = (Get-ChildItem -Path $OpenBLAS_DIR -Recurse -Directory -Filter "include" | Select-Object -First 1).FullName

# Configure and build with Visual Studio 2022
cmake -B build `
  -G "Visual Studio 17 2022" `
  -DCMAKE_BUILD_TYPE=Release `
  -DBLAS_LIBRARIES="$OPENBLAS_LIB" `
  -DLAPACK_LIBRARIES="$OPENBLAS_LIB" `
  -DOPENBLAS_INCLUDE_DIR="$OPENBLAS_INCLUDE"

cmake --build build --config Release --parallel

# Run the demo
.\build\Release\cholmod_demo.exe data\matrix.mtx
```

## Project Structure

```
├── cmake/
│   ├── find/           # Find modules for METIS and SuiteSparse
│   └── recipes/        # FetchContent recipes
│       ├── metis.cmake
│       └── suitesparse.cmake
├── data/
│   └── matrix.mtx      # Sample sparse matrix (Matrix Market format)
├── cholmod_demo.cpp    # Demo: Cholesky factorization and solve
└── CMakeLists.txt
```

## Usage in Your Project

Copy the `cmake/recipes/` folder to your project and include it in your `CMakeLists.txt`:

```cmake
include(${CMAKE_SOURCE_DIR}/cmake/recipes/suitesparse.cmake)

add_executable(my_app main.cpp)
target_link_libraries(my_app PRIVATE SuiteSparse::CHOLMOD)
target_include_directories(my_app PRIVATE ${SUITESPARSE_INCLUDE_DIRS})
```

## License

MIT License - See [LICENSE](LICENSE) for details.

