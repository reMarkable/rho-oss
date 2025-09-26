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

set(__rho_list_setting_ops APPEND SET)
set(__rho_list_modifying_ops POP_FRONT)
set(__rho_list_query_ops LENGTH PRETTY_PRINT GET)
set(__rho_list_helper_ops FOREACH_RANGE)

function(rho_list __rho_list_op)
  cmake_parse_arguments(PARSE_ARGV 1 __rho_list "" "" "")

  list(LENGTH __rho_list_UNPARSED_ARGUMENTS __rho_list_argn_length)

  if(__rho_list_op IN_LIST __rho_list_setting_ops)
    __rho_list_setting("${__rho_list_op}" "${__rho_list_UNPARSED_ARGUMENTS}" "${__rho_list_argn_length}")
  elseif(__rho_list_op IN_LIST __rho_list_modifying_ops)
    __rho_list_modifying("${__rho_list_op}" "${__rho_list_UNPARSED_ARGUMENTS}" "${__rho_list_argn_length}")
  elseif(__rho_list_op IN_LIST __rho_list_query_ops)
    __rho_list_query("${__rho_list_op}" "${__rho_list_UNPARSED_ARGUMENTS}" "${__rho_list_argn_length}")
  elseif(__rho_list_op IN_LIST __rho_list_helper_ops)
    __rho_list_helper("${__rho_list_op}" "${__rho_list_UNPARSED_ARGUMENTS}" "${__rho_list_argn_length}")
  else()
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: unknown operation: ${__rho_list_op}")
  endif()

  return(PROPAGATE ${__rho_list_out_vars})
endfunction()

function(__rho_list_setting __rho_list_op __rho_list_argn __rho_list_argn_length)
  if(__rho_list_argn_length LESS "1")
    message(FATAL_ERROR "rho_list(${__rho_list_op}): requires an output list variable")
  endif()

  __rho_list_pop_front(__rho_list_argn __rho_list_out)
  __rho_list_parse_list_varname(__rho_list_out)

  # remove empty elements
  string(REGEX REPLACE "^;+|;+$" "" __rho_list_argn "${__rho_list_argn}")
  string(REGEX REPLACE ";;+" ";" __rho_list_argn "${__rho_list_argn}")

  if(__rho_list_op STREQUAL "SET")
    set(__rho_list_result "${__rho_list_argn}")
  elseif(__rho_list_op STREQUAL "APPEND")
    __rho_list_read_list_var(__rho_list_result __rho_list_out)
    if("${__rho_list_result}" STREQUAL "")
      set(__rho_list_result "${__rho_list_argn}")
    elseif(NOT "${__rho_list_argn}" STREQUAL "")
      set(__rho_list_result "${__rho_list_result};${__rho_list_argn}")
    endif()
  else()
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: internal error, could not find op ${__rho_list_op}")
  endif()

  if(__rho_list_out_is_cache)
    if(NOT DEFINED "CACHE{${__rho_list_out}}")
      # not already in cache
      set("${__rho_list_out}" "${__rho_list_result}" CACHE INTERNAL "")
    else()
      set_property(CACHE "${__rho_list_out}" PROPERTY VALUE "${__rho_list_result}")
    endif()
    set(__rho_list_out_vars "" PARENT_SCOPE)
  else()
    set("${__rho_list_out}" "${__rho_list_result}" PARENT_SCOPE)
    set(__rho_list_out_vars "${__rho_list_out}" PARENT_SCOPE)
  endif()
endfunction()

function(__rho_list_modifying __rho_list_op __rho_list_argn __rho_list_argn_length)
  if(__rho_list_argn_length LESS "1")
    message(FATAL_ERROR "rho_list(${__rho_list_op}): requires an output list variable")
  endif()

  __rho_list_pop_front(__rho_list_argn __rho_list_var)
  __rho_list_parse_list_varname(__rho_list_var)
  __rho_list_read_list_var(__rho_list_lst __rho_list_var)

  set(__rho_list_out_vars "")
  if(__rho_list_op STREQUAL "POP_FRONT")
    __rho_list_check_max_argn_length(2)
    if("${__rho_list_lst}" STREQUAL "")
      message(FATAL_ERROR "rho_list(${__rho_list_op}): attempted to pop off of an empty list")
    endif()

    __rho_list_pop_front(__rho_list_lst __rho_list_front)

    if(__rho_list_argn_length EQUAL "2")
      __rho_list_pop_front(__rho_list_argn __rho_list_out)
      __rho_list_parse_out_varname(__rho_list_out)
      set("${__rho_list_out}" "${__rho_list_front}" PARENT_SCOPE)
      list(APPEND __rho_list_out_vars "${__rho_list_out}")
    endif()
  elseif(__rho_list_op STREQUAL "REMOVE")
    if(NOT "${__rho_list_argn_length}" EQUAL "3")
      message(FATAL_ERROR "rho_list(${__rho_list_op}): incorrect number of arguments")
    endif()
    list(GET __rho_list_argn 0 __rho_list_remove_op)
    list(GET __rho_list_argn 1 __rho_list_remove_argument)

    if(NOT __rho_list_remove_op STREQUAL "VALUE")
      message(FATAL_ERROR "rho_list(${__rho_list_op}): unknown operator ${__rho_list_remove_op}; expected VALUE")
    endif()

    set(__rho_list_result "")
    foreach(__rho_list_el IN LISTS __rho_list_lst)
      if(NOT __rho_list_el STREQUAL __rho_list_remove_argument)
        string(REPLACE ";" "\\;" __rho_list_el "${__rho_list_el}")
        list(APPEND __rho_list_result "${__rho_list_el}")
      endif()
    endforeach()
    set(__rho_list_lst "${__rho_list_result}")
  else()
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: internal error, could not find op ${__rho_list_op}")
  endif()

  if(__rho_list_var_is_cache)
    if(NOT DEFINED "CACHE{${__rho_list_var}}")
      # not already in cache
      set("${__rho_list_var}" "${__rho_list_lst}" CACHE INTERNAL "")
    else()
      set_property(CACHE "${__rho_list_var}" PROPERTY VALUE "${__rho_list_lst}")
    endif()
  else()
    list(APPEND __rho_list_out_vars "${__rho_list_var}")
    set("${__rho_list_var}" "${__rho_list_lst}" PARENT_SCOPE)
  endif()

  set(__rho_list_out_vars "${__rho_list_out_vars}" PARENT_SCOPE)
endfunction()

function(__rho_list_query __rho_list_op __rho_list_argn __rho_list_argn_length)
  if(__rho_list_argn_length LESS "2")
    message(FATAL_ERROR "rho_list(${__rho_list_op}): requires both an out variable and list argument")
  endif()

  __rho_list_pop_front(__rho_list_argn __rho_list_out)
  __rho_list_pop_front(__rho_list_argn __rho_list_var)
  __rho_list_parse_out_varname(__rho_list_out)
  __rho_list_parse_list_varname(__rho_list_var)

  __rho_list_read_list_var(__rho_list_lst __rho_list_var)
  set(__rho_list_out_vars "${__rho_list_out}")

  if(__rho_list_op STREQUAL "PRETTY_PRINT")
    __rho_list_check_max_argn_length(2)
    __rho_list_pretty_print(__rho_list_result 0 "${__rho_list_lst}")
  elseif(__rho_list_op STREQUAL "LENGTH")
    __rho_list_check_max_argn_length(2)
    list(LENGTH __rho_list_lst __rho_list_result)
  elseif(__rho_list_op STREQUAL "GET")
    __rho_list_check_max_argn_length(3)

    set(__rho_list_index "${__rho_list_argn}")
    list(LENGTH __rho_list_lst __rho_list_len)
    if(NOT (__rho_list_index LESS __rho_list_len AND __rho_list_index GREATER_EQUAL "-${__rho_list_len}"))
      if(NOT __rho_list_index MATCHES "^(0|-?[1-9][0-9]*)$")
        message(FATAL_ERROR "rho_list(${__rho_list_op}): invalid index: ${__rho_list_index}")
      endif()
      if(__rho_list_len EQUAL "0")
        message(FATAL_ERROR "rho_list(${__rho_list_op}): attempted to index into an empty list")
      endif()
      math(EXPR last_index "${__rho_list_len} - 1")
      message(FATAL_ERROR "rho_list(${__rho_list_op}): index ${__rho_list_index} outside of range [-${__rho_list_len}, ${last_index}]")
    endif()

    list(GET __rho_list_lst "${__rho_list_index}" __rho_list_result)
  else()
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: internal error, could not find op ${__rho_list_op}")
  endif()

  set(__rho_list_out_vars "${__rho_list_out_vars}" PARENT_SCOPE)
  set("${__rho_list_out}" "${__rho_list_result}" PARENT_SCOPE)
endfunction()

function(__rho_list_helper __rho_list_op __rho_list_argn __rho_list_argn_length)
  if(__rho_list_op STREQUAL "FOREACH_RANGE")
    if(__rho_list_argn_length LESS "1")
      message(FATAL_ERROR "rho_list(${__rho_list_op}): requires an output variable")
    endif()

    __rho_list_pop_front(__rho_list_argn __rho_list_out)
    __rho_list_parse_out_varname(__rho_list_out)

    cmake_parse_arguments(__rho_list_range "" "LENGTH;LIST;FIRST" "" ${__rho_list_argn})
    if(DEFINED __rho_list_range_UNPARSED_ARGUMENTS)
      __rho_list_pretty_print(extra_args 0 "${__rho_list_range_UNPARSED_ARGUMENTS}")
      message(FATAL_ERROR "rho_list(${__rho_list_op}) was passed extra arguments: ${extra_args}")
    endif()

    if(NOT DEFINED __rho_list_range_FIRST)
      set(__rho_list_range_FIRST 0)
    endif()

    if(NOT DEFINED __rho_list_range_LENGTH AND NOT DEFINED __rho_list_range_LIST)
      message(FATAL_ERROR "rho_list(${__rho_list_op}): requires either LIST or LENGTH to be passed")
    endif()
    if(DEFINED __rho_list_range_LENGTH AND DEFINED __rho_list_range_LIST)
      message(FATAL_ERROR "rho_list(${__rho_list_op}): requires only one of LIST or LENGTH to be passed")
    endif()

    if(NOT DEFINED __rho_list_range_LENGTH)
      __rho_list_parse_list_varname(__rho_list_range_LIST)
      __rho_list_read_list_var(__rho_list_lst __rho_list_range_LIST)
      list(LENGTH __rho_list_lst __rho_list_range_LENGTH)
    elseif(NOT __rho_list_range_LENGTH MATCHES "^([1-9][0-9]*|0)$")
      message(FATAL_ERROR "rho_list(${__rho_list_op}): LENGTH (${__rho_list_range_LENGTH}) must be a non-negative integer")
    endif()

    if(__rho_list_range_FIRST LESS __rho_list_range_LENGTH)
      math(EXPR __rho_list_last "${__rho_list_range_LENGTH} - 1")
      set(__rho_list_result "RANGE;${__rho_list_range_FIRST};${__rho_list_last}")
    else()
      set(__rho_list_result "")
    endif()
  else()
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: internal error, could not find op ${__rho_list_op}")
  endif()

  set(__rho_list_out_vars "${__rho_list_out}" PARENT_SCOPE)
  set("${__rho_list_out}" "${__rho_list_result}" PARENT_SCOPE)
endfunction()

macro(__rho_list_pop_front lst out)
  # list(POP_FRONT) also causes all the semicolons to be unescaped
  list(GET "${lst}" 0 "${out}")
  if("${${out}}" STREQUAL "${${lst}}")
    set("${lst}" "")
  else()
    string(LENGTH "${${out}};" __rho_list_pop_front_length)
    string(SUBSTRING "${${lst}}" "${__rho_list_pop_front_length}" -1 "${lst}")
  endif()
endmacro()

function(__rho_list_pretty_print out start lst)
  set(result "")
  list(LENGTH lst length)
  if(start GREATER_EQUAL length)
    set("${out}" "" PARENT_SCOPE)
    return()
  endif()

  math(EXPR last "${length} - 1")
  foreach(idx RANGE "${start}" "${last}")
    list(GET lst "${idx}" el)
    if(el STREQUAL "")
      set(el "\"\"")
    elseif(el MATCHES "\\\\|\n|\t| |\"|;")
      string(REPLACE "\\" [[\\]] el "${el}")
      string(REPLACE "\n" [[\n]] el "${el}")
      string(REPLACE "\t" [[\t]] el "${el}")
      string(REPLACE "\"" [[\"]] el "${el}")
      set(el "\"${el}\"")
    endif()

    if(NOT "${result}" STREQUAL "")
      set(result "${result} ${el}")
    else()
      set(result "${el}")
    endif()
  endforeach()

  set("${out}" "${result}" PARENT_SCOPE)
endfunction()

macro(__rho_list_parse_list_varname varname)
  if("${${varname}}" MATCHES [[^CACHE{(.*)}$]])
    set("${varname}" "${CMAKE_MATCH_1}")
    set("${varname}_is_cache" 1)
  elseif("${${varname}}" MATCHES [[{|}]])
    message(FATAL_ERROR "rho_list: invalid variable name: ${${varname}}")
  else()
    set("${varname}" "${${varname}}")
    set("${varname}_is_cache" 0)
  endif()
endmacro()

macro(__rho_list_parse_out_varname varname)
  if("${${varname}}" MATCHES [[^CACHE{(.*)}$]])
    message(FATAL_ERROR "rho_list(${__rho_list_op}): out variable must not be a cache variable: ${${varname}}")
  elseif("${${varname}}" MATCHES [[{|}]])
    message(FATAL_ERROR "rho_list: invalid variable name: ${${varname}}")
  else()
    set("${varname}" "${${varname}}")
  endif()
endmacro()

macro(__rho_list_check_max_argn_length n)
  if(__rho_list_argn_length GREATER "${n}")
    __rho_list_pretty_print(extra_args "${n}" "${__rho_list_argn}")
    message(FATAL_ERROR "rho_list(${__rho_list_op}) was passed extra arguments: ${extra_args}")
  endif()
endmacro()

macro(__rho_list_read_list_var out varbase)
  if("${${varbase}_is_cache}")
    get_property("${out}" CACHE "${${varbase}}" PROPERTY VALUE)
  else()
    __rho_check_varname_for_read(rho_list "${${varbase}}")
    set("${out}" "${${${varbase}}}")
  endif()
endmacro()

