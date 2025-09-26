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

function(rho_install target)
  rho_parse_arguments(POSITIONAL_ARGS 1)

  if(NOT TARGET "${target}")
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: passed a target (${target}) which is not built by this project")
  endif()

  rho_project_info(DEFAULT_TARGET default_target)
  if(target STREQUAL default_target)
    return()
  endif()

  get_target_property(type "${target}" TYPE)
  if(type STREQUAL "EXECUTABLE")
    rho_list(APPEND CACHE{__rho_install_exes} "${target}")
  else()
    rho_list(APPEND CACHE{__rho_install_libs} "${target}")
  endif()
endfunction()
