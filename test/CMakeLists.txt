#[===[
Copyright (c) reMarkable A.S.

Permission is hereby granted, free of charge, to any person obtaining a copy of
this software and associated documentation files (the “Software”), to deal in
the Software without restriction, including without limitation the rights to
use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
of the Software, and to permit persons to whom the Software is furnished to do
so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
]===]

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
