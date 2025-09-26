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
# - rho_assert
#
# none of these may depend on anything further down the list

function(rho_assert __rho_assert_op __rho_assert_var)
  if(__rho_assert_op MATCHES "^(JSON_EQUAL|EQUAL|STREQUAL)$")
    if(NOT ARGC EQUAL "3")
      message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}(${__rho_assert_op}): expected exactly 3 arguments (got ${ARGC})")
    endif()
    if(NOT DEFINED "${__rho_assert_var}")
      message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}(${__rho_assert_op}): ${__rho_assert_var} not defined")
    endif()
    if(__rho_assert_var MATCHES "^CACHE{(.*)}$")
      get_property(__rho_assert_value CACHE "${CMAKE_MATCH_1}" PROPERTY VALUE)
    else()
      __rho_check_varname_for_read(rho_assert "${__rho_assert_var}")
      set(__rho_assert_value "${${__rho_assert_var}}")
    endif()
    if(__rho_assert_op STREQUAL "JSON_EQUAL")
      string(JSON __rho_assert_equal EQUAL "${__rho_assert_value}" "${ARGV2}")
    elseif("${__rho_assert_value}" ${__rho_assert_op} "${ARGV2}")
      set(__rho_assert_equal 1)
    else()
      set(__rho_assert_equal 0)
    endif()

    if(NOT __rho_assert_equal)
      message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}(${__rho_assert_op}): \"${__rho_assert_value}\" != \"${ARGV2}\"")
    endif()
  elseif(__rho_assert_op STREQUAL "UNDEFINED")
    if(NOT ARGC EQUAL "2")
      message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}(${__rho_assert_op}): expected exactly 2 arguments (got ${ARGC})")
    endif()
    if(DEFINED "${__rho_assert_var}")
      message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}(${__rho_assert_op}): ${__rho_assert_var} defined")
    endif()
  else()
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: unknown operation ${__rho_assert_op}")
  endif()
endfunction()

