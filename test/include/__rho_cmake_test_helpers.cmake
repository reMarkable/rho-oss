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

function(rho_test_script_command output)
  rho_parse_arguments(POSITIONAL_ARGS 1
    OPTION_ARGS INFO RUN_TEST
    SINGLE_ARGS
      INDEX
      FILE
    REQUIRED_ARGS
      FILE)

  rho_list(SET defines)
  if(arg_INFO AND arg_RUN_TEST)
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: only one of INFO or RUN_TEST allowed")
  elseif(arg_INFO)
    rho_list(APPEND defines "-DRHO_TEST_PRINT_INFO=1")
  elseif(arg_RUN_TEST)
    if(NOT DEFINED arg_INDEX)
      message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: If RUN_TEST is passed, INDEX is required")
    endif()
  else()
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: One of RUN_TEST or INFO are required")
  endif()

  if(DEFINED arg_INDEX)
    rho_list(APPEND defines "-DRHO_TEST_INDEX=${arg_INDEX}")
  endif()

  rho_list(APPEND defines "-DCMAKE_MODULE_PATH=${CMAKE_MODULE_PATH}")
  rho_list(SET result "${CMAKE_COMMAND}" ${defines} "-P" "${arg_FILE}")
  set("${output}" "${result}" PARENT_SCOPE)
endfunction()

function(rho_test_parse_output var data cmd)
  if(NOT data MATCHES "===== BEGIN ${var} =====\n(.*)")
    message("Output of \"${cmd}\" does not contain the necessary information (asked for ${var});
    did you remember to call rho_test_finalize? See output\n${data}")
    message(FATAL_ERROR "no begin block found")
  endif()

  set(new_data "${CMAKE_MATCH_1}")
  if(new_data MATCHES "(.*)===== END ${var} =====")
    set(new_data "${CMAKE_MATCH_1}")
  endif()

  if(new_data MATCHES "===== (BEGIN|END)")
    message("Output of \"${cmd}\" contains nested blocks, or multiple blocks of the same information; this is a bug. See output\n${data}")
    message(FATAL_ERROR "Invalid output")
  endif()

  string(REPLACE " " "_" var "${var}")
  set("data_${var}" "${new_data}" PARENT_SCOPE)
endfunction()

