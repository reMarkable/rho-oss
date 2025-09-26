cmake_minimum_required(VERSION 3.25)

cmake_path(SET rho_base NORMALIZE "${CMAKE_CURRENT_LIST_DIR}/../..")
include("${rho_base}/cmake/misc/rho-boot.cmake")
project(rho::test-rho-boot VERSION 0.0.1 LANGUAGES CXX)

# don't do anything
