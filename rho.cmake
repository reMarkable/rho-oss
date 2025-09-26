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

if(CMAKE_CURRENT_SOURCE_DIR STREQUAL CMAKE_SOURCE_DIR)
  set(__rho_top_level_project 1)
else()
  set(__rho_top_level_project 0)
endif()

if(CMAKE_BINARY_DIR STREQUAL CMAKE_SOURCE_DIR)
  message(FATAL_ERROR "Attempted to configure the build directory to be the same as your source directory; this is not supported.")
endif()

if(__rho_top_level_project)
  option(DEVELOPER_MODE "Whether to build this project with developer options." ON)
  option(DEVELOPER_WARNINGS "Whether to use all of the warnings" "${DEVELOPER_MODE}")
  option(CMAKE_COMPILE_WARNING_AS_ERROR "Whether to have warnings as errors" "${DEVELOPER_MODE}")

  option(CMAKE_COLOR_DIAGNOSTICS "Enable color diagnostics throughout the generated build system" ON)

  option(CMAKE_EXPORT_COMPILE_COMMANDS "Enable output of compile commands during generation" ON)
  if(CMAKE_EXPORT_COMPILE_COMMANDS)
    ######################################################################
    # Copy compilation database to root directory for clangd or other lsp.
    # If possible (i.e., on not-Windows), we create a symbolic link so
    # that we don't have to worry about copying it.
    # Otherwise, we copy it as part of the build.
    ######################################################################
    file(CREATE_LINK
      "${CMAKE_BINARY_DIR}/compile_commands.json"
      "${CMAKE_SOURCE_DIR}/compile_commands.json"
      SYMBOLIC
      RESULT create_link_result)
    if(NOT create_link_result EQUAL "0")
      add_custom_target(copy-compile-commands ALL
        ${CMAKE_COMMAND} -E copy_if_different
          ${CMAKE_BINARY_DIR}/compile_commands.json
          ${CMAKE_SOURCE_DIR})
    endif()
  endif()

  # === RhoVcpkgFeatures.cmake ===
  # option(BUILD_TESTING "Whether to build tests" "${default_build_tests}")
  # option(FEATURE_${upper_feat}" "Enable the ${feature} feature")

  # === RhoTools.cmake ===
  # option(BUILD_SHARED_LIBS "Build shared libraries" ON)
endif()

# ==   Default version values   ==
set(__rho_default_codex_version "5.2.56")
set(__rho_default_vcpkg_version "ef7dbf94b9198bc58f45951adcf1f041fcbc5ea0") # 2025.06.13
set(__rho_vcpkg_privates_version "b45208344c8ca54fc2e8fe09bb4679bde9596d10")
set(__rho_wasi_sdk_version "2025-04-09")
set(__rho_python_utils_version "0.0.1#4")
# == End default version values ==

# TODO: this is not the correct way to solve this;
# if we don't do this, tests don't work because they can't find the DLLs.
if(WIN32 AND __rho_top_level_project)
  set(CMAKE_ARCHIVE_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/lib")
  set(CMAKE_LIBRARY_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
  set(CMAKE_RUNTIME_OUTPUT_DIRECTORY "${CMAKE_BINARY_DIR}/bin")
endif()

if(CMAKE_COMPILE_WARNING_AS_ERROR)
  set(__rho_warning "SEND_ERROR")
else()
  set(__rho_warning "WARNING")
endif()
set(__rho_github_issue "https://github.com/reMarkable/rho/issues/new")

set(RHO_CURRENT_MANIFEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/package")
if(NOT EXISTS "${RHO_CURRENT_MANIFEST_DIR}/vcpkg.json")
  message(FATAL_ERROR "You should place your vcpkg.json file inside the 'package' directory in the root of your project")
endif()

include("${CMAKE_CURRENT_LIST_DIR}/cmake/RhoCMakeHelpers.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/RhoTools.cmake")
include("${CMAKE_CURRENT_LIST_DIR}/cmake/RhoVcpkgFeatures.cmake")
# we want to print the warnings out after all the stuff in tools and features
include("${CMAKE_CURRENT_LIST_DIR}/cmake/RhoBootUpdate.cmake")

set(CMAKE_PROJECT_INCLUDE "${CMAKE_CURRENT_LIST_DIR}/cmake/RhoProject.cmake")

