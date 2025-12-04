cmake_minimum_required(VERSION 3.18 FATAL_ERROR)

project(gpu_ordering
        VERSION 0.1.0
        LANGUAGES C CXX)

# Language standards
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED TRUE)

################################################################################
# SECTION 1: Include Required Dependencies
################################################################################

# Include cmake recipes
include(${CMAKE_SOURCE_DIR}/cmake/recipes/metis.cmake)
include(${CMAKE_SOURCE_DIR}/cmake/recipes/suitesparse.cmake)

# OpenMP
find_package(OpenMP)

################################################################################
# SECTION 2: Create cholmod_demo executable
################################################################################

add_executable(cholmod_demo cholmod_demo.cpp)

# C++ compiler flags - cross-platform compatible
target_compile_options(cholmod_demo PRIVATE
    # MSVC flags
    $<$<CXX_COMPILER_ID:MSVC>:/W4 /MP /bigobj>
    # GCC flags
    $<$<AND:$<CXX_COMPILER_ID:GNU>,$<CONFIG:Release>>:-Wall -O3 -Wno-unused-function>
    $<$<AND:$<CXX_COMPILER_ID:GNU>,$<CONFIG:Debug>>:-Wall -O0 -g -Wno-unused-function>
    # Clang flags (including AppleClang)
    $<$<AND:$<CXX_COMPILER_ID:Clang>,$<CONFIG:Release>>:-Wall -O3 -Wno-unused-function>
    $<$<AND:$<CXX_COMPILER_ID:Clang>,$<CONFIG:Debug>>:-Wall -O0 -g -Wno-unused-function>
    $<$<AND:$<CXX_COMPILER_ID:AppleClang>,$<CONFIG:Release>>:-Wall -O3 -Wno-unused-function>
    $<$<AND:$<CXX_COMPILER_ID:AppleClang>,$<CONFIG:Debug>>:-Wall -O0 -g -Wno-unused-function>
)

# Link SuiteSparse CHOLMOD and dependencies
target_link_libraries(cholmod_demo PRIVATE
    SuiteSparse::CHOLMOD
    metis
)

# Link OpenMP if found
if(OpenMP_CXX_FOUND)
    target_link_libraries(cholmod_demo PRIVATE OpenMP::OpenMP_CXX)
endif()

# Include directories for SuiteSparse
target_include_directories(cholmod_demo PRIVATE ${SUITESPARSE_INCLUDE_DIRS})

# Compile definitions
target_compile_definitions(cholmod_demo PRIVATE
    $<$<CONFIG:Debug>:DEBUG>
    $<$<CONFIG:Release>:NDEBUG>
)
