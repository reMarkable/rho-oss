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

# These must be macros for variables to be propagated out
macro(rho_find_package __rho_find_package)
  cmake_parse_arguments(__rho_find_package_arg "HOST;REQUIRED" "" "" ${ARGN})
  set(__rho_find_package_args "${__rho_find_package_arg_UNPARSED_ARGUMENTS}")
  set(__rho_find_package_dep_args "${__rho_find_package_args}")

  if(__rho_find_package_arg_REQUIRED)
    rho_list(APPEND __rho_find_package_args REQUIRED)
  else()
    message("${__rho_warning}" "REQUIRED should be passed to all rho_find_package calls.")
  endif()

  if(__rho_find_package_arg_HOST)
    __rho_find_package_host("${__rho_find_package}" "${__rho_find_package_args}")
  else()
    find_package("${__rho_find_package}" ${__rho_find_package_args})
  endif()


  if(NOT __rho_find_package_arg_HOST)
    rho_list(APPEND CACHE{__rho_install_find_packages} "${__rho_find_package};${__rho_find_package_dep_args}")
  endif()
endmacro()

# Safe way to find host package in all scenarios
macro(__rho_find_package_host package args)
  # This addition to CMAKE_FIND_ROOT_PATH is for sysroot nonsense reasons.
  # If we can figure out how to avoid this, that would be very good.
  if(CMAKE_CROSSCOMPILING)
    list(APPEND CMAKE_FIND_ROOT_PATH "${VCPKG_INSTALLED_DIR}/${VCPKG_HOST_TRIPLET}")
  endif()

  message(STATUS "find package in ${VCPKG_INSTALLED_DIR}/${VCPKG_HOST_TRIPLET}")
  find_package(
    "${package}"
    ${args}
    NO_DEFAULT_PATH
    PATHS "${VCPKG_INSTALLED_DIR}/${VCPKG_HOST_TRIPLET}")

  if(CMAKE_CROSSCOMPILING)
    list(POP_BACK CMAKE_FIND_ROOT_PATH)
  endif()
endmacro()

