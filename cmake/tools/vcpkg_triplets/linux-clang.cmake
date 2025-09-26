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

set(VCPKG_TARGET_ARCHITECTURE %VCPKG_TARGET_ARCHITECTURE%)
set(VCPKG_CRT_LINKAGE %VCPKG_CRT_LINKAGE%)
set(VCPKG_LIBRARY_LINKAGE %VCPKG_LIBRARY_LINKAGE%)

set(VCPKG_CMAKE_SYSTEM_NAME Linux)
set(VCPKG_FIXUP_ELF_RPATH ON)

set(VCPKG_C_FLAGS "%VCPKG_C_FLAGS%")
set(VCPKG_CXX_FLAGS "%VCPKG_CXX_FLAGS%")
set(VCPKG_LINKER_FLAGS "%VCPKG_LINKER_FLAGS%")
set(VCPKG_CHAINLOAD_TOOLCHAIN_FILE "%TOOLCHAIN_DIR%/linux-clang.cmake")

