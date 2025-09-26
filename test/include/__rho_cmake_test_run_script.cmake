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

if(NOT DEFINED TEST_INDEX)
  message(FATAL_ERROR "TEST_INDEX must be defined")
endif()
if(NOT DEFINED TEST_FILE)
  message(FATAL_ERROR "TEST_FILE must be defined")
endif()

include("${CMAKE_CURRENT_LIST_DIR}/__rho_cmake_test_helpers.cmake")

rho_test_script_command(info_cmd FILE "${TEST_FILE}" INFO INDEX "${TEST_INDEX}")
rho_list(PRETTY_PRINT pretty_cmd info_cmd)
message(STATUS "Running ${pretty_cmd}")
execute_process(
  COMMAND ${info_cmd}
  RESULT_VARIABLE info_res
  OUTPUT_VARIABLE info_out
  ERROR_VARIABLE info_out
  ECHO_OUTPUT_VARIABLE)

if(NOT info_res EQUAL "0")
  message(FATAL_ERROR "Failed to get test info for test ${TEST_INDEX} in file \"${TEST_FILE}\":\n${info_out}")
endif()
rho_test_parse_output(INFO "${info_out}" "${info_cmd}")
string(JSON test_name GET "${data_INFO}" test)
string(JSON test_type GET "${data_INFO}" type)

rho_test_script_command(run_cmd FILE "${TEST_FILE}" RUN_TEST INDEX "${TEST_INDEX}")
rho_list(PRETTY_PRINT pretty_cmd run_cmd)
message(STATUS "Running ${pretty_cmd}")
execute_process(
  COMMAND ${run_cmd}
  RESULT_VARIABLE run_res
  OUTPUT_VARIABLE run_out
  ERROR_VARIABLE run_out
  ECHO_OUTPUT_VARIABLE
  ECHO_ERROR_VARIABLE)

if(run_out MATCHES "===== BEGIN TEST =====" AND NOT run_out MATCHES "===== END TEST =====")
  # make it easier to read
  message("====== END TEST ======")
endif()
rho_test_parse_output(TEST "${run_out}" "${run_cmd}")

if(test_type STREQUAL "fail")
  if(run_res EQUAL "0")
    message(FATAL_ERROR "${test_name}: fail test passed")
  endif()

  string(JSON fatal_error ERROR_VARIABLE no_fatal_error GET "${data_INFO}" fatal_error)
  if(NOT no_fatal_error)
    if(NOT data_TEST MATCHES "CMake Error at.*\\(message\\):\n(.*)\nCall Stack")
      message("${test_name}: did not message(FATAL_ERROR) (expected \"${fatal_error}\"")
      message(FATAL_ERROR "no fatal error")
    endif()

    string(STRIP "${CMAKE_MATCH_1}" message)
    string(REPLACE "\n  " " " message "${message}")

    if(NOT message MATCHES "${fatal_error}")
      message("${test_name}: message \"${message}\" did not match \"${fatal_error}\"")
      message(FATAL_ERROR "message did not match")
    endif()
  endif()
elseif(test_type STREQUAL "success")
  if(NOT run_res EQUAL "0")
    message(FATAL_ERROR "${test_name}: success test failed")
  endif()
else()
  message(FATAL_ERROR "run_script_test: unknown TEST_TYPE (${test_type}) for ${test_name} - expected one of fail, success")
endif()
