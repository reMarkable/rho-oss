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

include(GNUInstallDirs)
include(CMakePackageConfigHelpers)

set(__RHO_PROJECT_INCLUDE 1 CACHE INTERNAL "")
include("${CMAKE_CURRENT_LIST_DIR}/project/__rho_add_target.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/project/__rho_finalize_format_target.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/project/__rho_finalize_install.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/project/rho_find_package.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/project/rho_install.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/project/rho_project_info.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/project/rho_target_common_flags.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/project/rho_target_sources.cmake")
set(__RHO_PROJECT_INCLUDE 0 CACHE INTERNAL "")

block()
  if(NOT PROJECT_NAME MATCHES "^([-a-z0-9]+::)*[-a-z0-9]+$")
    message(FATAL_ERROR "Rho projects must have a project name made up of lowercase alphanumeric characters and hyphen-minus, separated by `::`")
  endif()
  rho_project_info(EXPECTED_PORT_NAME expected_vcpkg_name)
  rho_vcpkg_json(NAME vcpkg_name)
  if(DEFINED vcpkg_name AND NOT expected_vcpkg_name STREQUAL vcpkg_name)
    message(FATAL_ERROR "vcpkg.json has an incorrect name: we expected \"${expected_vcpkg_name}\" given the project name, but it was \"${vcpkg_name}\"")
  endif()
endblock()

cmake_language(DEFER DIRECTORY "${CMAKE_SOURCE_DIR}" CALL __rho_finalize_install)
cmake_language(DEFER DIRECTORY "${CMAKE_SOURCE_DIR}" CALL __rho_finalize_format_target)
