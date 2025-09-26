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

file(COPY
  "${CMAKE_CURRENT_LIST_DIR}/../cmake"
  "${CMAKE_CURRENT_LIST_DIR}/../vcpkg"
  "${CMAKE_CURRENT_LIST_DIR}/../rho.cmake"
  DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")

include("${CURRENT_PACKAGES_DIR}/share/${PORT}/cmake/RhoCMakeHelpers.cmake")
include("${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg/rho_install_copyright.cmake")

configure_file(
  "${CMAKE_CURRENT_LIST_DIR}/../vcpkg/vcpkg-port-config.cmake"
  "${CURRENT_PACKAGES_DIR}/share/${PORT}/vcpkg-port-config.cmake"
  COPYONLY)
rho_install_copyright(MIT
  COPYRIGHT_HOLDER "reMarkable A.S."
  COPYRIGHT_YEAR "2024-2025")

set(VCPKG_POLICY_CMAKE_HELPER_PORT enabled)
