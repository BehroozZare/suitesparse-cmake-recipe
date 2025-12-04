# FindBLAS.cmake
# Minimalist cross-platform BLAS finder
#
# This module finds BLAS libraries on Linux, macOS, and Windows.
#
# Result variables:
#   BLAS_FOUND        - True if BLAS was found
#   BLAS_INCLUDES     - Include directories for BLAS
#   BLAS_LIBRARIES    - Libraries to link against

if(BLAS_INCLUDES AND BLAS_LIBRARIES)
    set(BLAS_FIND_QUIETLY TRUE)
endif()

# Platform-specific handling
if(APPLE)
    # macOS: Use Accelerate framework
    find_library(BLAS_LIBRARIES
        NAMES Accelerate
        PATHS /System/Library/Frameworks
    )
    if(BLAS_LIBRARIES)
        set(BLAS_INCLUDES "")
        set(BLAS_FOUND TRUE)
    endif()
elseif(WIN32)
    # Windows: Look for OpenBLAS
    find_path(BLAS_INCLUDES
        NAMES cblas.h openblas/cblas.h
        PATHS
        $ENV{BLAS_ROOT}
        $ENV{OpenBLAS_HOME}
        ${BLAS_ROOT}
        ${OpenBLAS_HOME}
        "C:/OpenBLAS"
        "C:/Program Files/OpenBLAS"
        "C:/Program Files (x86)/OpenBLAS"
        PATH_SUFFIXES
        include
        include/openblas
    )

    find_library(BLAS_LIBRARIES
        NAMES openblas libopenblas blas
        PATHS
        $ENV{BLAS_ROOT}
        $ENV{OpenBLAS_HOME}
        ${BLAS_ROOT}
        ${OpenBLAS_HOME}
        "C:/OpenBLAS"
        "C:/Program Files/OpenBLAS"
        "C:/Program Files (x86)/OpenBLAS"
        PATH_SUFFIXES
        lib
        lib64
    )
else()
    # Linux/Unix: Look for OpenBLAS or reference BLAS
    find_path(BLAS_INCLUDES
        NAMES cblas.h
        PATHS
        $ENV{BLAS_ROOT}
        ${BLAS_ROOT}
        /usr/include
        /usr/local/include
        /usr/include/openblas
        /usr/local/include/openblas
        PATH_SUFFIXES
        openblas
    )

    find_library(BLAS_LIBRARIES
        NAMES openblas blas cblas
        PATHS
        $ENV{BLAS_ROOT}
        ${BLAS_ROOT}
        /usr/lib
        /usr/lib64
        /usr/local/lib
        /usr/local/lib64
        /usr/lib/x86_64-linux-gnu
        PATH_SUFFIXES
        lib
        lib64
    )
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(BLAS DEFAULT_MSG
    BLAS_LIBRARIES)

mark_as_advanced(BLAS_INCLUDES BLAS_LIBRARIES)

