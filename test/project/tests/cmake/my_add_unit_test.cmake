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

find_package(Catch2 CONFIG REQUIRED)

include(CTest)
include(Catch)

# sets all nessary default things
function(my_add_unit_test test_name)
  rho_parse_arguments(POSITIONAL_ARGS 1)

  cmake_path(
    GET CMAKE_CURRENT_LIST_DIR
    FILENAME library_name)

  set(test_file "${test_name}_test.cpp")
  set(test_target "${library_name}-${test_name}")

  add_executable("${test_target}" "${test_file}")

  target_link_libraries("${test_target}"
    PRIVATE
      ${PROJECT_NAME}::${library_name}
      Catch2::Catch2WithMain)

  catch_discover_tests(${test_target} TEST_PREFIX "${test_target}:")
endfunction()
