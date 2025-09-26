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

if(NOT _VCPKG_WINDOWS_CLANG_TOOLCHAIN)
  set(_VCPKG_WINDOWS_CLANG_TOOLCHAIN 1)
  set(CMAKE_MSVC_RUNTIME_LIBRARY "MultiThreaded$<$<CONFIG:Debug>:Debug>$<$<STREQUAL:${VCPKG_CRT_LINKAGE},dynamic>:DLL>" CACHE STRING "")
  set(CMAKE_MSVC_DEBUG_INFORMATION_FORMAT "")

  cmake_policy(VERSION 3.25)
  list(APPEND CMAKE_TRY_COMPILE_PLATFORM_VARIABLES
     VCPKG_CRT_LINKAGE VCPKG_TARGET_ARCHITECTURE VCPKG_SET_CHARSET_FLAG
     VCPKG_C_FLAGS VCPKG_CXX_FLAGS
     VCPKG_C_FLAGS_DEBUG VCPKG_CXX_FLAGS_DEBUG
     VCPKG_C_FLAGS_RELEASE VCPKG_CXX_FLAGS_RELEASE
     VCPKG_LINKER_FLAGS VCPKG_LINKER_FLAGS_RELEASE VCPKG_LINKER_FLAGS_DEBUG
     VCPKG_PLATFORM_TOOLSET
  )

  set(CMAKE_SYSTEM_NAME Windows CACHE STRING "")

  if(VCPKG_TARGET_ARCHITECTURE STREQUAL "x86")
    set(__rho_clang_triple "x86-pc-windows-msvc")
    set(CMAKE_SYSTEM_PROCESSOR x86 CACHE STRING "")
  elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "x64")
    set(__rho_clang_triple "x86_64-pc-windows-msvc")
    set(CMAKE_SYSTEM_PROCESSOR AMD64 CACHE STRING "")
  elseif(VCPKG_TARGET_ARCHITECTURE STREQUAL "arm64")
    set(__rho_clang_triple "aarch64-pc-windows-msvc")
    set(CMAKE_SYSTEM_PROCESSOR ARM64 CACHE STRING "")
  else()
    message(FATAL_ERROR "Unsupported VCPKG_TARGET_ARCHITECTURE: ${VCPKG_TARGET_ARCHITECTURE}")
  endif()

  if(DEFINED VCPKG_CMAKE_SYSTEM_VERSION)
    set(CMAKE_SYSTEM_VERSION "${VCPKG_CMAKE_SYSTEM_VERSION}" CACHE STRING "" FORCE)
  endif()

  if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
    if(CMAKE_SYSTEM_PROCESSOR STREQUAL CMAKE_HOST_SYSTEM_PROCESSOR)
      set(CMAKE_CROSSCOMPILING OFF CACHE STRING "")
    elseif(CMAKE_SYSTEM_PROCESSOR STREQUAL "x86")
      # any of the four platforms can run x86 binaries
      set(CMAKE_CROSSCOMPILING OFF CACHE STRING "")
    elseif(CMAKE_HOST_SYSTEM_PROCESSOR STREQUAL "ARM64")
      # arm64 can run binaries of any of the four platforms after Windows 11
      set(CMAKE_CROSSCOMPILING OFF CACHE STRING "")
    endif()

    if(NOT DEFINED CMAKE_SYSTEM_VERSION)
      set(CMAKE_SYSTEM_VERSION "${CMAKE_HOST_SYSTEM_VERSION}" CACHE STRING "")
    endif()
  endif()

  find_program(__rho_clang_cl "clang-cl")
  if(NOT __rho_clang_cl)
    message(FATAL_ERROR "Could not find clang-cl - is it installed via Visual Studio?")
  endif()
  set(CMAKE_C_COMPILER "${__rho_clang_cl}")
  set(CMAKE_CXX_COMPILER "${__rho_clang_cl}")
  unset(__rho_clang_cl)
  set(CMAKE_C_FLAGS " /nologo /DWIN32 /D_WINDOWS /utf-8 --target=${__rho_clang_triple} ${VCPKG_C_FLAGS}" CACHE STRING "")
  set(CMAKE_CXX_FLAGS " /nologo /DWIN32 /D_WINDOWS /utf-8 /GR /EHsc --target=${__rho_clang_triple} ${VCPKG_CXX_FLAGS}" CACHE STRING "")

  set(CMAKE_RC_FLAGS "-c65001 /DWIN32" CACHE STRING "")

  if(VCPKG_CRT_LINKAGE STREQUAL "dynamic")
    set(__rho_crt_link_flag_prefix "/MD")
  elseif(VCPKG_CRT_LINKAGE STREQUAL "static")
    set(__rho_crt_link_flag_prefix "/MT")
  else()
    message(FATAL_ERROR "Invalid setting for VCPKG_CRT_LINKAGE: \"${VCPKG_CRT_LINKAGE}\". It must be \"static\" or \"dynamic\"")
  endif()

  set(CMAKE_CXX_FLAGS_DEBUG " /D_DEBUG ${__rho_crt_link_flag_prefix}d /Z7 /Ob0 /Od /RTC1 ${VCPKG_CXX_FLAGS_DEBUG}" CACHE STRING "")
  set(CMAKE_C_FLAGS_DEBUG " /D_DEBUG ${__rho_crt_link_flag_prefix}d /Z7 /Ob0 /Od /RTC1 ${VCPKG_C_FLAGS_DEBUG}" CACHE STRING "")
  set(CMAKE_CXX_FLAGS_RELEASE " ${__rho_crt_link_flag_prefix} /O2 /Oi /Gy /DNDEBUG /Z7 ${VCPKG_CXX_FLAGS_RELEASE}" CACHE STRING "")
  set(CMAKE_C_FLAGS_RELEASE " ${__rho_crt_link_flag_prefix} /O2 /Oi /Gy /DNDEBUG /Z7 ${VCPKG_C_FLAGS_RELEASE}" CACHE STRING "")
  unset(__rho_crt_link_flag_prefix)

  string(APPEND CMAKE_STATIC_LINKER_FLAGS_RELEASE_INIT " /nologo ")

  set(__rho_all_linker_flags "/nologo /DEBUG /INCREMENTAL:NO /OPT:REF /OPT:ICF ${VCPKG_LINKER_FLAGS} ${VCPKG_LINKER_FLAGS_RELEASE}")
  set(CMAKE_MODULE_LINKER_FLAGS_RELEASE "${__rho_all_linker_flags}" CACHE STRING "")
  set(CMAKE_SHARED_LINKER_FLAGS_RELEASE "${__rho_all_linker_flags}" CACHE STRING "")
  set(CMAKE_EXE_LINKER_FLAGS_RELEASE "${__rho_all_linker_flags}" CACHE STRING "")
  unset(__rho_all_linker_flags)

  string(APPEND CMAKE_STATIC_LINKER_FLAGS_DEBUG_INIT " /nologo ")
  set(__rho_all_linker_flags "/nologo ${VCPKG_LINKER_FLAGS} ${VCPKG_LINKER_FLAGS_DEBUG}")
  string(APPEND CMAKE_MODULE_LINKER_FLAGS_DEBUG_INIT " ${__rho_all_linker_flags}")
  string(APPEND CMAKE_SHARED_LINKER_FLAGS_DEBUG_INIT " ${__rho_all_linker_flags}")
  string(APPEND CMAKE_EXE_LINKER_FLAGS_DEBUG_INIT " ${__rho_all_linker_flags}")
endif()
