cmake_minimum_required(VERSION 3.25)

cmake_path(SET RHO_DIRECTORY NORMALIZE "${CMAKE_CURRENT_LIST_DIR}/../..")
include("${RHO_DIRECTORY}/cmake/misc/rho-boot.cmake")
project(rho::test-package VERSION 0.0.1 LANGUAGES CXX)

rho_find_package(fmt CONFIG REQUIRED)

add_subdirectory(src/library)
add_subdirectory(src/foo/boo)
add_subdirectory(src/cli)

include(CTest)
if(BUILD_TESTING)
  add_subdirectory(tests)
endif()
