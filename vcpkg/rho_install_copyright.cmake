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

function(rho_install_copyright license)
  rho_parse_arguments(POSITIONAL_ARGS 1
    SINGLE_ARGS
      COPYRIGHT_HOLDER COPYRIGHT_YEAR
    REQUIRED_ARGS
      COPYRIGHT_HOLDER COPYRIGHT_YEAR)

  if(license MATCHES "^licenseRef-")
    set(license_file "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/licenses/proprietary") 
  else()
    string(TOLOWER "${license}" lower_license)
    set(license_file "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/licenses/${lower_license}")
  endif()

  if(NOT EXISTS "${license_file}")
    file(GLOB known_licenses
      RELATIVE "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/licenses/"
      "${CMAKE_CURRENT_FUNCTION_LIST_DIR}/licenses/*")
    list(JOIN known_licenses "\n  - " known_licenses)
    message("Unknown license: ${license}; known licenses are:\n  - ${known_licenses}")
    message(FATAL_ERROR "unknown license")
  endif()

  configure_file(
    "${license_file}"
    "${CURRENT_PACKAGES_DIR}/share/${PORT}/copyright"
    @ONLY)
endfunction()
