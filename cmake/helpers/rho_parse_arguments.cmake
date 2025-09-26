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

macro(rho_parse_arguments)
  # get a correctly escaped list of the parent's arguments, to pass to rho_parse_arguments
  cmake_parse_arguments(PARSE_ARGV 0 __rho_parse_arguments "" "" "")
  __rho_parse_arguments("${CMAKE_CURRENT_FUNCTION}" "${__rho_parse_arguments_UNPARSED_ARGUMENTS}" "${ARGV}")
endmacro()

function(__rho_parse_arguments parent_name parent_args my_args)
  # because rho_parse_arguments is a macro, it is _not possible_ to correctly take list arguments;
  # therefore, we're just going to use the classic version of cmake_parse_arguments.
  cmake_parse_arguments(arg
    "ALLOW_UNPARSED_ARGS"
    "POSITIONAL_ARGS;ARG_PREFIX"
    "OPTION_ARGS;SINGLE_ARGS;MULTI_ARGS;REQUIRED_ARGS"
    ${my_args})

  if(DEFINED arg_UNPARSED_ARGUMENTS)
    rho_list(PRETTY_PRINT pretty_args arg_UNPARSED_ARGUMENTS)
    message(FATAL_ERROR "rho_parse_arguments was passed extra arguments: ${pretty_args}")
  endif()
  if(NOT DEFINED arg_ARG_PREFIX)
    set(arg_ARG_PREFIX "arg")
  endif()
  if(NOT DEFINED arg_POSITIONAL_ARGS)
    set(arg_POSITIONAL_ARGS 0)
  endif()

  # allow rpa keywords to be taken as arguments; for example:
  # rho_parse_arguments(OPTION_ARGS "#ALLOW_UNPARSED_ARGS")
  foreach(lst arg_OPTION_ARGS arg_SINGLE_ARGS arg_MULTI_ARGS arg_REQUIRED_ARGS)
    list(TRANSFORM "${lst}" REPLACE "^#" "")
  endforeach()

  rho_list(SET all_keywords ${arg_OPTION_ARGS} ${arg_SINGLE_ARGS} ${arg_MULTI_ARGS})
  list(SORT all_keywords)
  set(last_keyword "")
  foreach(kw IN LISTS all_keywords)
    if(kw STREQUAL "UNPARSED_ARGS")
      message(FATAL_ERROR "rho_parse_arguments was passed the keyword UNPARSED_ARGS - this is not a valid keyword argument")
    elseif(kw STREQUAL last_keyword)
      message(FATAL_ERROR "rho_parse_arguments was passed the same keyword twice: ${kw}")
    endif()
  endforeach()

  foreach(opt IN LISTS arg_OPTION_ARGS)
    set("parent_arg_${opt}" 0)
  endforeach()
  foreach(kw IN LISTS arg_SINGLE_ARGS arg_MULTI_ARGS)
    unset("parent_arg_${kw}")
  endforeach()

  rho_list(FOREACH_RANGE parent_args_range LIST parent_args FIRST "${arg_POSITIONAL_ARGS}")
  unset(current_single)
  unset(current_multi)
  foreach(index ${parent_args_range})
    rho_list(GET element parent_args "${index}")
    set(raw_element 0)
    if(element MATCHES "^#(.*)$")
      set(raw_element 1)
      set(element "${CMAKE_MATCH_1}")
    endif()

    if(NOT raw_element AND element IN_LIST all_keywords)
      unset(keyword_without_args)
      if(DEFINED current_single)
        set(keyword_without_args "${current_single}")
      elseif(DEFINED current_multi AND NOT DEFINED "parent_arg_${current_multi}")
        set(keyword_without_args "${current_multi}")
      endif()

      if(DEFINED keyword_without_args)
        message(FATAL_ERROR "${parent_name}: argument keyword ${keyword_without_args} was not given a value before switching to new keyword ${element}; \
        if you wish to have ${element} be an argument to ${keyword_without_args}, you need to use raw argument syntax: \"#${element}\"")
      endif()

      if(element IN_LIST arg_OPTION_ARGS)
        if("${parent_arg_${element}}")
          message(FATAL_ERROR "${parent_name}: keyword ${element} was passed multiple times")
        endif()
        set("parent_arg_${element}" 1)
        unset(current_multi)
      elseif(element IN_LIST arg_SINGLE_ARGS)
        if(DEFINED "parent_arg_${element}")
          message(FATAL_ERROR "${parent_name}: keyword ${element} was passed multiple times")
        endif()
        set(current_single "${element}")
        unset(current_multi)
      elseif(element IN_LIST arg_MULTI_ARGS)
        if(DEFINED "parent_arg_${element}")
          message(FATAL_ERROR "${parent_name}: keyword ${element} was passed multiple times")
        endif()
        set(current_multi "${element}")
      else()
        message(FATAL_ERROR "rho_parse_arguments: internal error: element (${element}) IN_LIST all_keywords (${all_keywords})\
        but not IN_LIST arg_OPTION_ARGS (${arg_OPTION_ARGS}), arg_SINGLE_ARGS (${arg_SINGLE_ARGS}), arg_MULTI_ARGS (${arg_MULTI_ARGS})")
      endif()

      continue()
    endif()

    if(DEFINED current_single)
      set("parent_arg_${current_single}" "${element}")
      unset(current_single)
    elseif(DEFINED current_multi)
      rho_list(APPEND "parent_arg_${current_multi}" "${element}")
    else()
      rho_list(APPEND "parent_arg_UNPARSED_ARGS" "${element}")
    endif()
  endforeach()

  unset(keyword_without_args)
  if(DEFINED current_single)
    set(keyword_without_args "${current_single}")
  elseif(DEFINED current_multi AND NOT DEFINED "parent_arg_${current_multi}")
    set(keyword_without_args "${current_multi}")
  endif()

  if(DEFINED keyword_without_args)
    message(FATAL_ERROR "${parent_name}: argument keyword ${keyword_without_args} was not given a value before the end of the argument list")
  endif()

  if(DEFINED parent_arg_UNPARSED_ARGS)
    if(NOT arg_ALLOW_UNPARSED_ARGS)
      rho_list(PRETTY_PRINT pretty_args parent_arg_UNPARSED_ARGS)
      message(FATAL_ERROR "${parent_name} was passed extra arguments: ${pretty_args}")
    else()
      set("${arg_ARG_PREFIX}_UNPARSED_ARGS" "${parent_arg_UNPARSED_ARGS}" PARENT_SCOPE)
    endif()
  else()
    unset("${arg_ARG_PREFIX}_UNPARSED_ARGS" PARENT_SCOPE)
  endif()

  foreach(req IN LISTS arg_REQUIRED_ARGS)
    if(NOT DEFINED "parent_arg_${req}")
      message(FATAL_ERROR "${parent_name}: keyword ${req} must be specified")
    endif()
  endforeach()

  foreach(arg IN LISTS arg_OPTION_ARGS arg_SINGLE_ARGS arg_MULTI_ARGS)
    if(DEFINED "parent_arg_${arg}")
      set("${arg_ARG_PREFIX}_${arg}" "${parent_arg_${arg}}" PARENT_SCOPE)
    else()
      unset("${arg_ARG_PREFIX}_${arg}" PARENT_SCOPE)
    endif()
  endforeach()
endfunction()

