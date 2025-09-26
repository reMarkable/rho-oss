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

function(rho_forward_arguments)
  rho_parse_arguments(
    ARG_PREFIX __rho_forward_arguments
    SINGLE_ARGS "#ARG_PREFIX"
    MULTI_ARGS
      "#OPTION_ARGS"
      "#SINGLE_ARGS"
      "#MULTI_ARGS")

  if(NOT DEFINED __rho_forward_arguments_ARG_PREFIX)
    set(__rho_forward_arguments_ARG_PREFIX "param")
  endif()

  foreach(__rho_forward_arguments_opt IN LISTS __rho_forward_arguments_OPTION_ARGS)
    __rho_forward_arguments_parse_arg("${CMAKE_CURRENT_FUNCTION}" "${__rho_forward_arguments_opt}")

    rho_list(SET __rho_forward_arguments_result)
    if(NOT DEFINED "${__rho_forward_arguments_input}")
      message("${__rho_warning}" "${CMAKE_CURRENT_FUNCTION}: OPTION \"${__rho_forward_arguments_input}\" was not defined; did you pass a boolean value rather than a variable name?")
    elseif("${${__rho_forward_arguments_input}}")
      rho_list(SET __rho_forward_arguments_result "${__rho_forward_arguments_output}")
    endif()

    set("${__rho_forward_arguments_ARG_PREFIX}_${__rho_forward_arguments_output}" "${__rho_forward_arguments_result}" PARENT_SCOPE)
  endforeach()

  foreach(__rho_forward_arguments_arg IN LISTS __rho_forward_arguments_SINGLE_ARGS)
    __rho_forward_arguments_parse_arg("${CMAKE_CURRENT_FUNCTION}" "${__rho_forward_arguments_arg}")

    if(NOT "${${__rho_forward_arguments_input}}" STREQUAL "")
      # for single args, we need to re-escape
      rho_list(SET __rho_forward_arguments_result "${__rho_forward_arguments_output}" "${${__rho_forward_arguments_input}}")
    else()
      rho_list(SET __rho_forward_arguments_result)
    endif()
    set("${__rho_forward_arguments_ARG_PREFIX}_${__rho_forward_arguments_output}" "${__rho_forward_arguments_result}" PARENT_SCOPE)
  endforeach()

  foreach(__rho_forward_arguments_arg IN LISTS __rho_forward_arguments_MULTI_ARGS)
    __rho_forward_arguments_parse_arg("${CMAKE_CURRENT_FUNCTION}" "${__rho_forward_arguments_arg}")

    if(NOT "${${__rho_forward_arguments_input}}" STREQUAL "")
      rho_list(SET __rho_forward_arguments_result "${__rho_forward_arguments_output}" ${${__rho_forward_arguments_input}})
    else()
      rho_list(SET __rho_forward_arguments_result)
    endif()
    set("${__rho_forward_arguments_ARG_PREFIX}_${__rho_forward_arguments_output}" "${__rho_forward_arguments_result}" PARENT_SCOPE)
  endforeach()
endfunction()

function(__rho_forward_arguments_parse_arg fname arg)
  if(arg MATCHES [[=.*=]] OR arg MATCHES [[{|}]])
    message(FATAL_ERROR "${fname}: Invalid argument \"${arg}\" passed; expected \"VARNAME\" or \"VARNAME=OTHERVAR\"")
  elseif(arg MATCHES [[^(.*)=(.*)$]])
    set(__rho_forward_arguments_output "${CMAKE_MATCH_1}" PARENT_SCOPE)
    set(__rho_forward_arguments_input "${CMAKE_MATCH_2}" PARENT_SCOPE)
    __rho_check_varname_for_read("${fname}" "${CMAKE_MATCH_2}")
  else()
    set(__rho_forward_arguments_output "${arg}" PARENT_SCOPE)
    set(__rho_forward_arguments_input "arg_${arg}" PARENT_SCOPE)
  endif()
endfunction()
