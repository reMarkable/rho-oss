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

if(NOT __RHO_CMAKE_HELPERS_INCLUDE)
  message(FATAL_ERROR "You have included ${CMAKE_CURRENT_LIST_FILE} by itself. This is not supported.")
endif()

# Note on dependencies:
# To avoid multiple recursion, each of these depends on others in an order:
#
# - rho_list
# - rho_parse_arguments
# - rho_forward_arguments
# - rho_escape
#
# none of these may depend on anything further down the list

# rho_escape(TO_JSON_STRING out "hi")
# rho_escape(TO_JSON_ARRAY out "hi")
# rho_escape(FROM_JSON_ARRAY out "hi")

function(rho_escape op out string)
  rho_parse_arguments(POSITIONAL_ARGS 3)

  if(op STREQUAL "TO_JSON_STRING")
    string(REPLACE "\\" [[\\]] string "${string}")
    string(REPLACE "\n" [[\n]] string "${string}")
    string(REPLACE "\"" [[\"]] string "${string}")
    set("${out}" "\"${string}\"" PARENT_SCOPE)
  elseif(op STREQUAL "TO_JSON_ARRAY")
    set(res "[]")
    rho_list(LENGTH length string)
    foreach(el IN LISTS string)
      if(el MATCHES ";")
        rho_escape(TO_JSON_ARRAY el "${el}")
        string(JSON res SET "${res}" "${length}" "${el}")
      else()
        rho_escape(TO_JSON_STRING el "${el}")
        string(JSON res SET "${res}" "${length}" "${el}")
      endif()
    endforeach()
    set("${out}" "${res}" PARENT_SCOPE)
  elseif(op STREQUAL "FROM_JSON_ARRAY")
    string(JSON length ERROR_VARIABLE no_length LENGTH "${string}")
    if(no_length)
      message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}(${op}): argument must be an array")
    endif()
    rho_list(SET res)
    if(NOT length EQUAL "0")
      math(EXPR last "${length} - 1")
      foreach(index RANGE 0 "${last}")
        string(JSON type TYPE "${string}" "${index}")
        if(NOT type STREQUAL "STRING")
          message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}(${op}): argument must be an array of strings (found ${type})")
        endif()
        string(JSON el GET "${string}" "${index}")
        rho_list(APPEND res "${el}")
      endforeach()
    endif()
    set("${out}" "${res}" PARENT_SCOPE)
  else()
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: Unknown operation \"${op}\"")
  endif()
endfunction()
