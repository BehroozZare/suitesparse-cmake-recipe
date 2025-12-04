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

### Build

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

