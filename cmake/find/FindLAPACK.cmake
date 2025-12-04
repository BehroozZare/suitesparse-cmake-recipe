# FindLAPACK.cmake
# Minimalist cross-platform LAPACK finder
#
# This module finds LAPACK libraries on Linux, macOS, and Windows.
# Priority: Intel oneAPI MKL > OpenBLAS > System LAPACK
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
    # macOS: Check for Intel oneAPI MKL first, then Accelerate framework
    find_path(LAPACK_INCLUDES
        NAMES mkl_lapack.h mkl.h
        PATHS
        $ENV{MKLROOT}
        $ENV{ONEAPI_ROOT}/mkl/latest
        /opt/intel/oneapi/mkl/latest
        PATH_SUFFIXES
        include
    )
    
    find_library(LAPACK_LIBRARIES
        NAMES mkl_rt
        PATHS
        $ENV{MKLROOT}
        $ENV{ONEAPI_ROOT}/mkl/latest
        /opt/intel/oneapi/mkl/latest
        PATH_SUFFIXES
        lib
        lib/intel64
    )
    
    # Fall back to Accelerate framework if MKL not found
    if(NOT LAPACK_LIBRARIES)
        find_library(LAPACK_LIBRARIES
            NAMES Accelerate
            PATHS /System/Library/Frameworks
        )
        if(LAPACK_LIBRARIES)
            set(LAPACK_INCLUDES "")
            set(LAPACK_FOUND TRUE)
        endif()
    endif()
elseif(WIN32)
    # Windows: Check for Intel oneAPI MKL first
    find_path(LAPACK_INCLUDES
        NAMES mkl_lapack.h mkl.h
        PATHS
        $ENV{MKLROOT}
        $ENV{ONEAPI_ROOT}/mkl/latest
        "C:/Program Files (x86)/Intel/oneAPI/mkl/latest"
        "C:/Program Files/Intel/oneAPI/mkl/latest"
        PATH_SUFFIXES
        include
    )
    
    find_library(LAPACK_LIBRARIES
        NAMES mkl_rt
        PATHS
        $ENV{MKLROOT}
        $ENV{ONEAPI_ROOT}/mkl/latest
        "C:/Program Files (x86)/Intel/oneAPI/mkl/latest"
        "C:/Program Files/Intel/oneAPI/mkl/latest"
        PATH_SUFFIXES
        lib
        lib/intel64
    )
    
    # Fall back to OpenBLAS if MKL not found
    if(NOT LAPACK_LIBRARIES)
        # Note: OpenBLAS zip extracts with version subfolder, so we search recursively
        file(GLOB OPENBLAS_SUBDIRS 
            "C:/OpenBLAS/OpenBLAS-*"
            "$ENV{OpenBLAS_HOME}/OpenBLAS-*"
        )
        
        find_path(LAPACK_INCLUDES
            NAMES lapacke.h lapack.h
            PATHS
            $ENV{LAPACK_ROOT}
            $ENV{OpenBLAS_HOME}
            ${LAPACK_ROOT}
            ${OpenBLAS_HOME}
            ${OPENBLAS_SUBDIRS}
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
            ${OPENBLAS_SUBDIRS}
            "C:/OpenBLAS"
            "C:/Program Files/OpenBLAS"
            "C:/Program Files (x86)/OpenBLAS"
            PATH_SUFFIXES
            lib
            lib64
        )
    endif()
else()
    # Linux/Unix: Check for Intel oneAPI MKL first
    find_path(LAPACK_INCLUDES
        NAMES mkl_lapack.h mkl.h
        PATHS
        $ENV{MKLROOT}
        $ENV{ONEAPI_ROOT}/mkl/latest
        /opt/intel/oneapi/mkl/latest
        PATH_SUFFIXES
        include
    )
    
    find_library(LAPACK_LIBRARIES
        NAMES mkl_rt
        PATHS
        $ENV{MKLROOT}
        $ENV{ONEAPI_ROOT}/mkl/latest
        /opt/intel/oneapi/mkl/latest
        PATH_SUFFIXES
        lib
        lib/intel64
    )
    
    # Fall back to LAPACK or OpenBLAS if MKL not found
    if(NOT LAPACK_LIBRARIES)
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
endif()

include(FindPackageHandleStandardArgs)
find_package_handle_standard_args(LAPACK DEFAULT_MSG
    LAPACK_LIBRARIES)

mark_as_advanced(LAPACK_INCLUDES LAPACK_LIBRARIES)
