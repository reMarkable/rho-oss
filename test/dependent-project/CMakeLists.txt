cmake_minimum_required(VERSION 3.25)

cmake_path(SET RHO_DIRECTORY NORMALIZE "${CMAKE_CURRENT_LIST_DIR}/../..")
set(VCPKG_OVERLAY_PORTS "${RHO_DIRECTORY}/package;${RHO_DIRECTORY}/test/project/package")
include("${RHO_DIRECTORY}/cmake/misc/rho-boot.cmake")
project(rho::test-dependent-package VERSION 0.0.1 LANGUAGES CXX)

rho_find_package(rho-test-package CONFIG REQUIRED)
# make sure that we can find_package twice (this was a bug)
rho_find_package(rho-test-package CONFIG REQUIRED)

rho_add_executable(test-dependent-package
  SOURCE_BASE src)
target_link_libraries(test-dependent-package
  PRIVATE
    rho::test-package::library
    rho::test-package::foo::boo)

target_compile_definitions(test-dependent-package
  PRIVATE
    TEST_PACKAGE_CLI="$<TARGET_FILE:rho::test-package::cli>")

rho_add_executable(test-dependent-package-with-default-target
  SOURCE_BASE src)
target_link_libraries(test-dependent-package-with-default-target
  PRIVATE
    rho::test-package)

target_compile_definitions(test-dependent-package-with-default-target
  PRIVATE
    TEST_PACKAGE_CLI="$<TARGET_FILE:rho::test-package::cli>")
