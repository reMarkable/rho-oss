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
cmake_policy(VERSION 3.25)

include(RhoCMakeHelpers)
include("${CMAKE_CURRENT_LIST_DIR}/__rho_cmake_test_helpers.cmake")

option(RHO_TEST_PRINT_INFO "Print test info (including count)")
set(RHO_TEST_INDEX -1 CACHE STRING "The index of the test to be run")

if(NOT RHO_TEST_PRINT_INFO AND RHO_TEST_INDEX EQUAL "-1")
  message(FATAL_ERROR "RhoTestCmake: you must choose one of printing the test info (RHO_TEST_PRINT_INFO), or running a test (RHO_TEST_INDEX), or printing a specific test's info")
endif()

set(__RHO_TEST_INFO "{\"tests\":[]}" CACHE INTERNAL "")
set(__RHO_TEST_COUNT "0" CACHE INTERNAL "")
function(rho_test)
  rho_parse_arguments(
    SINGLE_ARGS
      FAIL
      SUCCESS
      FATAL_ERROR
      EXPR)

  unset(fatal_error)
  if(DEFINED arg_FAIL)
    if(DEFINED arg_SUCCESS)
      message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: both SUCCESS and FAIL passed, this is nonsensical")
    endif()
    set(type "fail")
    set(test "${arg_FAIL}")
  elseif(DEFINED arg_SUCCESS)
    if(DEFINED arg_FATAL_ERROR)
      message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: both SUCCESS and FATAL_ERROR passed, this is nonsensical")
    endif()

    set(type "success")
    set(test "${arg_SUCCESS}")
  else()
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: neither SUCCESS nor FAIL passed, this is nonsensical.")
  endif()

  set(test_info "{}")
  string(JSON test_info SET "${test_info}" test "\"${test}\"")
  string(JSON test_info SET "${test_info}" type "\"${type}\"")
  if(DEFINED arg_FATAL_ERROR)
    rho_escape(TO_JSON_STRING fatal_error "${arg_FATAL_ERROR}")
    string(JSON test_info SET "${test_info}" fatal_error "${fatal_error}")
  endif()
  if(DEFINED arg_EXPR)
    rho_escape(TO_JSON_STRING expr "${arg_EXPR}")
    string(JSON test_info SET "${test_info}" expr "${expr}")
  endif()

  string(JSON new_rho_test_info SET "${__RHO_TEST_INFO}" tests "${__RHO_TEST_COUNT}" "${test_info}")
  set(__RHO_TEST_INFO "${new_rho_test_info}" CACHE INTERNAL "")

  math(EXPR new_count "${__RHO_TEST_COUNT} + 1")
  set(__RHO_TEST_COUNT "${new_count}" CACHE INTERNAL "")
endfunction()

function(rho_test_finalize)
  if(NOT ARGC EQUAL "0")
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: no arguments should be passed to rho_test_finalize")
  endif()

  if(RHO_TEST_PRINT_INFO)
    message("===== BEGIN INFO =====")
    if(RHO_TEST_INDEX GREATER_EQUAL __RHO_TEST_COUNT)
      message(FATAL_ERROR "RhoTestCmake: invalid test index passed (${RHO_TEST_INDEX} >= ${__RHO_TEST_COUNT})")
    endif()
    if(RHO_TEST_INDEX EQUAL "-1")
      message("${__RHO_TEST_INFO}")
    else()
      string(JSON test_info GET "${__RHO_TEST_INFO}" tests "${RHO_TEST_INDEX}")
      message("${test_info}")
    endif()
    message("===== END INFO =====")
  else()
    if(RHO_TEST_INDEX GREATER_EQUAL __RHO_TEST_COUNT)
      message(FATAL_ERROR "RhoTestCmake: invalid test index passed (${RHO_TEST_INDEX} >= ${__RHO_TEST_COUNT})")
    endif()

    string(JSON test GET "${__RHO_TEST_INFO}" tests "${RHO_TEST_INDEX}" test)
    string(JSON expr ERROR_VARIABLE no_expr GET "${__RHO_TEST_INFO}" tests "${RHO_TEST_INDEX}" expr)

    message("===== BEGIN TEST =====")
    if(NOT no_expr)
      cmake_language(EVAL CODE "${expr}")
    else()
      cmake_language(CALL "${test}")
    endif()
    message("===== END TEST =====")
  endif()
endfunction()
