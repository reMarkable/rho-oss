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

set(__rho_project_sources_to_format "" CACHE INTERNAL "All of the files to format. Added by rho_target_sources.")

# called as part of a DIRECTORY DEFER
function(__rho_finalize_format_target)
  string(REPLACE ";" "\n" sources "${__rho_project_sources_to_format}")
  file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/all_rho_format_sources.txt" "${sources}")

  find_program(CLANG_FORMAT clang-format)
  add_custom_target(format
    COMMENT "Formatting all known source files"
    VERBATIM
    WORKING_DIRECTORY "${CMAKE_SOURCE_DIR}"
    COMMAND
      "${CLANG_FORMAT}" -i
        "--style=file:${CMAKE_CURRENT_FUNCTION_LIST_DIR}/../misc/default-clang-format.ini"
        "--files=${CMAKE_CURRENT_BINARY_DIR}/all_rho_format_sources.txt")
endfunction()
