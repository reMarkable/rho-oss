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

# Note on dependencies:
# To avoid multiple recursion, each of these depends on others in an order:
#
# - rho_list
# - rho_parse_arguments
# - rho_forward_arguments
# - rho_escape
#
# none of these may depend on anything further down the list

function(__rho_check_varname_for_read function varname)
  if(varname MATCHES [=[^(ARGV[0-9]*|ARGC|ARGN|CMAKE_CURRENT_FUNCTION(_LIST_(DIR|FILE|LINE))?)$]=])
    message(FATAL_ERROR "${function}: invalid variable name: ${varname}; \
this variable gets reset as part of function calling, so it is not \
possible to access the value of it from inside ${function}.")
  elseif(varname MATCHES "^__${function}.*")
    message(FATAL_ERROR "${function}: invalid variable name: ${varname}; \
this is an internal variable name to ${function}. It is reserved for internal \
implementation details.")
  endif()
endfunction()

function(__rho_block_message)
  if(ARGC EQUAL "0")
    message(FATAL_ERROR "Internal error: passed no arguments to ${CMAKE_CURRENT_FUNCTION}")
  endif()
  cmake_parse_arguments(PARSE_ARGV 0 arg "" "" "")
  string(REPLACE "\n" ";" args "${arg_UNPARSED_ARGUMENTS}")

  set(max_len 0)
  foreach(element IN LISTS args)
    string(LENGTH "${element}" cur_len)
    if(cur_len GREATER max_len)
      set(max_len "${cur_len}")
    endif()
  endforeach()

  math(EXPR line_size "${max_len} + 6") # 2 = plus ' ' on each side
  string(REPEAT "=" "${line_size}" block_line)

  set(result "${block_line}\n${block_line}\n")
  foreach(element IN LISTS args)
    string(LENGTH "${element}" len)
    math(EXPR len_diff "${max_len} - ${len}")
    math(EXPR diff_is_odd "${len_diff} % 2")
    math(EXPR front_count "${len_diff} / 2")
    math(EXPR back_count "${front_count} + ${diff_is_odd}")
    string(REPEAT " " "${front_count}" front_space)
    string(REPEAT " " "${back_count}" back_space)
    set(result "${result}== ${front_space}${element}${back_space} ==\n")
  endforeach()

  message("${result}${block_line}\n${block_line}\n")
endfunction()

# This function is included in modified form in rho-boot.cmake;
# if you modify it here, please update it in rho-boot also if necessary.
function(__rho_get_rm_build_dir out)
  if(DEFINED ENV{RM_BUILD_DIR})
    set(cache_dir "$ENV{RM_BUILD_DIR}")
  elseif("${__rho_host_os}" STREQUAL "windows")
    set(cache_dir "$ENV{LOCALAPPDATA}/rm-build/cache")
  else()
    set(cache_dir "$ENV{HOME}/.cache/rm-build")
  endif()
  set("${out}" "${cache_dir}" PARENT_SCOPE)
endfunction()

set(__RHO_CMAKE_HELPERS_INCLUDE 1 CACHE INTERNAL "")
include("${CMAKE_CURRENT_LIST_DIR}/helpers/rho_assert.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/helpers/rho_escape.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/helpers/rho_forward_arguments.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/helpers/rho_list.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/helpers/rho_parse_arguments.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/helpers/rho_vcpkg_json.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/helpers/__rho_git.cmake")
set(__RHO_CMAKE_HELPERS_INCLUDE 0 CACHE INTERNAL "")
