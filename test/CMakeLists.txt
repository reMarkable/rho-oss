cmake_minimum_required(VERSION 3.25)

set(BUILD_TESTING ON CACHE BOOL "" FORCE)

project(rho-test)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}/include" "${CMAKE_CURRENT_LIST_DIR}/../cmake")

include(RhoCMakeTestBuild)

rho_test_script(unit/rho_escape.cmake)
rho_test_script(unit/rho_forward_arguments.cmake)
rho_test_script(unit/rho_list.cmake)
rho_test_script(unit/rho_parse_arguments.cmake)

execute_process(
  COMMAND git rev-parse HEAD
  OUTPUT_VARIABLE head_version
  RESULT_VARIABLE rev_parse_res)
if(NOT rev_parse_res EQUAL "0")
  message(FATAL_ERROR "failed to rev-parse HEAD to figure out what RHO_VERSION should be")
endif()
string(STRIP "${head_version}" head_version)

add_test(NAME rho-boot.cleanup
  COMMAND cmake -E rm -rf -- "${CMAKE_CURRENT_BINARY_DIR}/rho-boot")
add_test(
  NAME rho-boot.default-rev
  COMMAND cmake
    -B "${CMAKE_CURRENT_BINARY_DIR}/rho-boot/default"
    -S "${CMAKE_CURRENT_LIST_DIR}/rho-boot"
    -G Ninja)
add_test(
  NAME rho-boot.current-rev
  COMMAND cmake
    -B "${CMAKE_CURRENT_BINARY_DIR}/rho-boot/current"
    -S "${CMAKE_CURRENT_LIST_DIR}/rho-boot"
    -G Ninja
    "-DRHO_VERSION=${head_version}")

set_tests_properties(rho-boot.default-rev rho-boot.current-rev
  PROPERTIES FIXTURES_REQUIRED rho-boot)
set_tests_properties(rho-boot.cleanup
  PROPERTIES FIXTURES_CLEANUP rho-boot)
set_tests_properties(rho-boot.default-rev rho-boot.current-rev
   PROPERTIES RESOURCE_LOCK rho-git-directory)
