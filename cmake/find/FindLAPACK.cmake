# FindLAPACK.cmake
# Minimalist cross-platform LAPACK finder
#
# This module finds LAPACK libraries on Linux, macOS, and Windows.
# Note: LAPACK requires BLAS, so BLAS is found first.
#
# Result variables:
#   LAPACK_FOUND        - True if LAPACK was found
#   LAPACK_INCLUDES     - Include directories for LAPACK
#   LAPACK_LIBRARIES    - Libraries to link against

if(LAPACK_INCLUDES AND LAPACK_LIBRARIES)
    set(LAPACK_FIND_QUIETLY TRUE)
endif()

# Platform-specific handling
if(APPLE)
    # macOS: Use Accelerate framework (includes both BLAS and LAPACK)
    find_library(LAPACK_LIBRARIES
        NAMES Accelerate
        PATHS /System/Library/Frameworks
    )
    if(LAPACK_LIBRARIES)
        set(LAPACK_INCLUDES "")
        set(LAPACK_FOUND TRUE)
    endif()
elseif(WIN32)
    # Windows: Look for OpenBLAS (includes LAPACK) or separate LAPACK
    find_path(LAPACK_INCLUDES
        NAMES lapacke.h lapack.h
        PATHS
        $ENV{LAPACK_ROOT}
        $ENV{OpenBLAS_HOME}
        ${LAPACK_ROOT}
        ${OpenBLAS_HOME}
        "C:/OpenBLAS"
        "C:/Program Files/OpenBLAS"
        "C:/Program Files (x86)/OpenBLAS"
        PATH_SUFFIXES
        include
        include/openblas
    )

    find_library(LAPACK_LIBRARIES
        NAMES openblas libopenblas lapack liblapack
        PATHS
        $ENV{LAPACK_ROOT}
        $ENV{OpenBLAS_HOME}
        ${LAPACK_ROOT}
        ${OpenBLAS_HOME}
        "C:/OpenBLAS"
        "C:/Program Files/OpenBLAS"
        "C:/Program Files (x86)/OpenBLAS"
        PATH_SUFFIXES
        lib
        lib64
    )
else()
    # Linux/Unix: Look for LAPACK or LAPACKE
    find_path(LAPACK_INCLUDES
        NAMES lapacke.h lapack.h
        PATHS
        $ENV{LAPACK_ROOT}
        ${LAPACK_ROOT}
        /usr/include
        /usr/local/include
        /usr/include/lapack
        /usr/local/include/lapack
        PATH_SUFFIXES
        lapack
        openblas
    )

    find_library(LAPACK_LIBRARIES
        NAMES lapack lapacke openblas
        PATHS
        $ENV{LAPACK_ROOT}
        ${LAPACK_ROOT}
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
find_package_handle_standard_args(LAPACK DEFAULT_MSG
    LAPACK_LIBRARIES)

mark_as_advanced(LAPACK_INCLUDES LAPACK_LIBRARIES)

