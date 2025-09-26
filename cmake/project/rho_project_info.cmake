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

if(NOT __RHO_PROJECT_INCLUDE)
  message(FATAL_ERROR "You have included ${CMAKE_CURRENT_LIST_FILE} by itself. This is not supported.")
endif()

function(rho_project_info op out)
  rho_parse_arguments(POSITIONAL_ARGS 2)

  if(op STREQUAL "TARGET_NAMESPACE")
    set("${out}" "${PROJECT_NAME}" PARENT_SCOPE)
  elseif(op STREQUAL "BINARY_PREFIX")
    string(REPLACE "::" "_" result "${PROJECT_NAME}")
    set("${out}" "${result}" PARENT_SCOPE)
  elseif(op STREQUAL "EXPECTED_PORT_NAME")
    string(REPLACE "::" "-" result "${PROJECT_NAME}")
    set("${out}" "${result}" PARENT_SCOPE)
  elseif(op STREQUAL "INCLUDE_BASE")
    string(REPLACE "::" "/" result "${PROJECT_NAME}")
    set("${out}" "${result}" PARENT_SCOPE)
  elseif(op STREQUAL "DEFAULT_TARGET")
    string(FIND "${PROJECT_NAME}" "::" index REVERSE)
    if(index EQUAL -1)
      set("${out}" "${PROJECT_NAME}" PARENT_SCOPE)
    else()
      math(EXPR start_name "${index} + 2")
      string(SUBSTRING "${PROJECT_NAME}" "${start_name}" -1 value)
      set("${out}" "${value}" PARENT_SCOPE)
    endif()
  elseif(op STREQUAL "DEFAULT_TARGET_NAMESPACE")
    string(FIND "${PROJECT_NAME}" "::" index REVERSE)
    if(index EQUAL -1)
      set("${out}" "${PROJECT_NAME}" PARENT_SCOPE)
    else()
      string(SUBSTRING "${PROJECT_NAME}" 0 "${index}" value)
      set("${out}" "${value}" PARENT_SCOPE)
    endif()
  else()
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: unknown operator ${op}")
  endif()
endfunction()
