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

foreach(file IN ITEMS "../cmake" "../vcpkg")
  cmake_path(ABSOLUTE_PATH file BASE_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}" NORMALIZE)
  if(IS_DIRECTORY "${file}")
    file(GLOB_RECURSE sources "${file}/*")
    list(APPEND VCPKG_HASH_ADDITIONAL_FILES "${sources}")
  elseif(EXISTS "${file}")
    list(APPEND VCPKG_HASH_ADDITIONAL_FILES "${file}")
  else()
    message(FATAL_ERROR "incorrectly written vcpkg-abi-settings.cmake: ${file} does not exist")
  endif()
endforeach()
