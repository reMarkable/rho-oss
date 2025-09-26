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

include_guard(GLOBAL)
cmake_policy(VERSION 3.29)

include(RhoCMakeHelpers)
include("${CMAKE_CURRENT_LIST_DIR}/__rho_cmake_test_helpers.cmake")
include(CTest)

# we want to use the list dir of this file, not the one of the file that calls rho_test_script
set(__rho_cmake_test_path_to_script "${CMAKE_CURRENT_LIST_DIR}/__rho_cmake_test_run_script.cmake")

function(rho_test_script file)
  string(REPLACE "/" "-" test_prefix "${file}")
  cmake_path(REMOVE_EXTENSION test_prefix)

  cmake_path(ABSOLUTE_PATH file BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}")

  # make sure that, when the test file changes, to reconfigure and rebuild the test list
  set_property(DIRECTORY APPEND PROPERTY CMAKE_CONFIGURE_DEPENDS "${file}")
  rho_test_script_command(info_cmd FILE "${file}" INFO)
  rho_list(PRETTY_PRINT pretty_cmd info_cmd)
  message(STATUS "Running ${pretty_cmd}")
  execute_process(
    COMMAND ${info_cmd}
    RESULT_VARIABLE info_res
    OUTPUT_VARIABLE info_out
    ERROR_VARIABLE info_out)

  rho_test_parse_output(INFO "${info_out}" "${info_cmd}")
  string(JSON tests_type ERROR_VARIABLE tests_err TYPE "${data_INFO}" tests)
  if(NOT tests_type STREQUAL "ARRAY")
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: ${file} output malformed test information:\n${data_INFO}")
  endif()

  string(JSON tests_len LENGTH "${data_INFO}" tests)
  math(EXPR last_test "${tests_len} - 1")
  foreach(index RANGE 0 "${last_test}")
    string(JSON test_name GET "${data_INFO}" tests "${index}" test)
    string(JSON test_type GET "${data_INFO}" tests "${index}" type)
    string(JSON test_fatal_error ERROR_VARIABLE no_test_fatal_error GET "${data_INFO}" tests "${index}" fatal_error)

    rho_list(SET defines
      "-DTEST_INDEX=${index}"
      "-DTEST_FILE=${file}"
      "-DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}")
    if(NOT no_test_fatal_error)
      rho_list(APPEND defines "-DTEST_FATAL_ERROR=${test_fatal_error}")
    endif()

    add_test(NAME "${test_prefix}.${test_name}"
      COMMAND "${CMAKE_COMMAND}" ${defines} "-P" "${__rho_cmake_test_path_to_script}")
  endforeach()
endfunction()
