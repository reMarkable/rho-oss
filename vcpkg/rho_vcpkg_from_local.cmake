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

function(rho_vcpkg_from_local out_source_path)
  rho_parse_arguments(
    POSITIONAL_ARGS 1
    SINGLE_ARGS DIRECTORY)

  if(DEFINED _RHO_VCPKG_PACKAGE_PATH)
    set(package_path "${_RHO_VCPKG_PACKAGE_PATH}")
  else()
    # results in the list directory of the portfile.cmake that calls this function
    set(package_path "${CMAKE_CURRENT_LIST_DIR}")
    set(_RHO_VCPKG_PACKAGE_PATH "${package_path}" PARENT_SCOPE)
  endif()

  cmake_path(ABSOLUTE_PATH arg_DIRECTORY BASE_DIRECTORY "${package_path}" NORMALIZE)
  set("${out_source_path}" "${arg_DIRECTORY}" PARENT_SCOPE)
endfunction()
