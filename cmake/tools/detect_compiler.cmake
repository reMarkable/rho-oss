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

# Sets the following variables:
# - CMAKE_C_COMPILER and CMAKE_CXX_COMPILER to the correct compiler
# - __rho_target_architecture_flag to the flag to pass to clang to get it to be a cross compiler
# - RHO_TARGET_COMPILER to one of:
#   - clang
#   - gcc
#   - msvc
# - RHO_TARGET_ARCHITECTURE to the target architecture
# based on the following, in order:
# - CMAKE_C[XX]_COMPILER
# - CC and CXX
# - RHO_TARGET_COMPILER and RHO_TARGET_ARCHITECTURE
# if RHO_TARGET_COMPILER or RHO_TARGET_ARCHITECTURE would have a different
# value after running this algorithm, and they were not set to "default", then
# detect_compiler will send an error

function(__rho_compiler_type out_vendor out_arch path args)
  separate_arguments(args NATIVE_COMMAND "${args}")
  execute_process(
    COMMAND "${path}" ${args} -v # error for cl, but it still prints everything we need
    OUTPUT_VARIABLE output
    ERROR_VARIABLE output
    RESULT_VARIABLE result)

  if(NOT result MATCHES "^[0-9]+$")
    __rho_block_message(
      "Could not run compiler '${path}'; are you sure you set your compiler"
      "and your environment correctly?"
      "execute_process result: ${result}"
      "Note: on Windows, make sure you open a developer command prompt")
    message(FATAL_ERROR "Could not find compiler")
  endif()

  # Microsoft (R) C/C++ Optimizing Compiler Version 19.42.34435 for ARM64
  if(output MATCHES "^Microsoft \\(R\\) C/C\\+\\+ Optimizing Compiler .*(x86|x64|ARM|ARM64)\n")
    set("${out_vendor}" "msvc" PARENT_SCOPE)
    if(CMAKE_MATCH_1 STREQUAL "x86")
      set("${out_arch}" "x86" PARENT_SCOPE)
    elseif(CMAKE_MATCH_1 STREQUAL "x64")
      set("${out_arch}" "x64" PARENT_SCOPE)
    elseif(CMAKE_MATCH_1 STREQUAL "ARM")
      set("${out_arch}" "arm" PARENT_SCOPE)
    elseif(CMAKE_MATCH_1 STREQUAL "ARM64")
      set("${out_arch}" "arm64" PARENT_SCOPE)
    else()
      message(FATAL_ERROR "Internal error: unknown CMAKE_MATCH_1 '${CMAKE_MATCH_1}'")
    endif()
  # [vendor ]clang version 18.1.8
  # Target: x86_64-pc-windows-msvc
  elseif(output MATCHES "clang version")
    set("${out_vendor}" "clang" PARENT_SCOPE)
    if(NOT output MATCHES "Target: ([^\n]*)\n")
      __rho_block_message(
        "Could not figure out clang's target architecture; output was:"
        "${output}"
        "Please report this to ${__rho_github_issue}")
      message(FATAL_ERROR "Could not find clang target architecture")
    endif()

    set(triple "${CMAKE_MATCH_1}")

    if(triple MATCHES "^(x86|i[3-9]86)-")
      set("${out_arch}" "x86" PARENT_SCOPE)
    elseif(triple MATCHES "^(amd64|x86_64)-")
      set("${out_arch}" "x64" PARENT_SCOPE)
    elseif(triple MATCHES "^(arm64|aarch64)-")
      set("${out_arch}" "arm64" PARENT_SCOPE)
    elseif(triple MATCHES "^arm")
      set("${out_arch}" "arm" PARENT_SCOPE)
    else()
      __rho_block_message(
        "Unknown clang architecture: ${triple}"
        "Please report this to ${__rho_github_issue}")
      message(FATAL_ERROR "Unknown clang target architecture")
    endif()
  # Target: aarch64-linux-gnu
  # gcc version 13.3.0 (Ubuntu 13.3.0-6ubuntu2~24.04)
  elseif(output MATCHES "")
    set("${out_vendor}" "gcc" PARENT_SCOPE)
    if(NOT output MATCHES "Target: (.*)\n")
      __rho_block_message(
        "Could not figure out gcc's target architecture; output was:"
        "${output}"
        "Please report this to ${__rho_github_issue}")
      message(FATAL_ERROR "Could not find gcc target architecture")
    endif()

    set(triple "${CMAKE_MATCH_1}")

    if(triple MATCHES "^(x86|i[3-9]86)-")
      set("${out_arch}" "x86" PARENT_SCOPE)
    elseif(triple MATCHES "^(amd64|x86_64)-")
      set("${out_arch}" "x64" PARENT_SCOPE)
    elseif(triple MATCHES "^(arm64|aarch64)-")
      set("${out_arch}" "arm64" PARENT_SCOPE)
    elseif(triple MATCHES "^arm")
      set("${out_arch}" "arm" PARENT_SCOPE)
    else()
      __rho_block_message(
        "Unknown gcc architecture: ${triple}"
        "Please report this to ${__rho_github_issue}")
      message(FATAL_ERROR "Unknown gcc target architecture")
    endif()
  else()
    __rho_block_message(
      "Unknown compiler. Output was:"
      "${output}"
      "Arguments were:"
      "${path} ${args} --version"
      "Please report this to ${__rho_github_issue}")
    message(FATAL_ERROR "Unknown compiler")
  endif()
endfunction()

function(__rho_add_flag var flag)
  string(REPLACE "+" "\\+" regex_escaped_flag "${flag}")
  if(DEFINED "${var}")
    if(NOT "${${var}}" MATCHES "( |^)${regex_escaped_flag}( |\$)")
      set("${var}" "${${var}} ${flag} " CACHE STRING "" FORCE)
    endif()
  else()
    if(NOT "${${var}_INIT}" MATCHES "( |^)${flag}( |\$)")
      set("${var}_INIT" "${${var}_INIT} ${flag} " CACHE STRING "" FORCE)
    endif()
  endif()
endfunction()

set(__rho_compiler_cxx "")
if(DEFINED CMAKE_CXX_COMPILER)
  set(__rho_compiler_cxx "${CMAKE_CXX_COMPILER}")
elseif(DEFINED ENV{CXX})
  set(__rho_compiler_cxx "$ENV{CXX}")
endif()
set(__rho_compiler_cxx_flags "")
if(DEFINED CMAKE_CXX_FLAGS)
  set(__rho_compiler_cxx_flags "${CMAKE_CXX_FLAGS} $ENV{CXXFLAGS}")
else()
  set(__rho_compiler_cxx_flags "${CMAKE_CXX_FLAGS_INIT} $ENV{CXXFLAGS}")
endif()

set(__rho_compiler_c "")
if(DEFINED CMAKE_C_COMPILER)
  set(__rho_compiler_c "${CMAKE_C_COMPILER}")
elseif(DEFINED ENV{CC})
  set(__rho_compiler_c "$ENV{CC}")
endif()
set(__rho_compiler_c_flags "")
if(DEFINED CMAKE_C_FLAGS)
  set(__rho_compiler_c_flags "${CMAKE_C_FLAGS} $ENV{CFLAGS}")
else()
  set(__rho_compiler_c_flags "${CMAKE_C_FLAGS_INIT} $ENV{CFLAGS}")
endif()

if(__rho_compiler_cxx STREQUAL "" AND NOT __rho_compiler_c STREQUAL "")
  if(__rho_compiler_c MATCHES "^(.*)gcc(-[a-z0-9.])?$")
    set(__rho_compiler_cxx "${CMAKE_MATCH_1}g++${CMAKE_MATCH_2}")
  elseif(__rho_compiler_c MATCHES "^(.*)cc$")
    set(__rho_compiler_cxx "${CMAKE_MATCH_1}c++")
  elseif(__rho_compiler_c MATCHES "^(.*)clang(-[a-z0-9.])?$")
    set(__rho_compiler_cxx "${CMAKE_MATCH_1}clang++${CMAKE_MATCH_2}")
  else()
    set(__rho_compiler_cxx "${__rho_compiler_c}")
  endif()
endif()
if(__rho_compiler_c STREQUAL "" AND NOT __rho_compiler_cxx STREQUAL "")
  if(__rho_compiler_c MATCHES "^(.*)g\\+\\+(-[a-z0-9.])?$")
    set(__rho_compiler_cxx "${CMAKE_MATCH_1}gcc${CMAKE_MATCH_2}")
  elseif(__rho_compiler_cxx MATCHES "^(.*)c\\+\\+$")
    set(__rho_compiler_c "${CMAKE_MATCH_1}cc")
  elseif(__rho_compiler_cxx MATCHES "^(.*)clang\\+\\+(-[a-z0-9.])?$")
    set(__rho_compiler_c "${CMAKE_MATCH_1}clang${CMAKE_MATCH_2}")
  else()
    set(__rho_compiler_c "${__rho_compiler_cxx}")
  endif()
endif()

if(__rho_compiler_cxx STREQUAL "") # both are unset
  if(RHO_TARGET_COMPILER STREQUAL "clang")
    if(__rho_host_os STREQUAL "windows")
      set(__rho_compiler_c "clang-cl.exe")
      set(__rho_compiler_cxx "clang-cl.exe")
    else()
      set(__rho_compiler_c "clang")
      set(__rho_compiler_cxx "clang++")
    endif()
  elseif(RHO_TARGET_COMPILER STREQUAL "gcc")
    if(__rho_host_os STREQUAL "linux")
      set(__rho_compiler_c "gcc")
      set(__rho_compiler_cxx "g++")
    else()
      __rho_block_message(
        "Using RHO_TARGET_COMPILER to find gcc automatically is unsupported on Windows and macOS."
        "Set your CMAKE_C_COMPILER and CMAKE_CXX_COMPILER to point at gcc.")
      message(FATAL_ERROR "Attempted to find gcc automatically on Windows and macOS.")
    endif()
  elseif(RHO_TARGET_COMPILER STREQUAL "msvc")
    if(NOT __rho_host_os STREQUAL "windows")
      message(FATAL_ERROR "Attempted to use MSVC on a non-windows platform.")
    endif()
    set(__rho_compiler_c "cl.exe")
    set(__rho_compiler_cxx "cl.exe")
  elseif(RHO_TARGET_COMPILER STREQUAL "default")
    if(__rho_host_os STREQUAL "windows")
      set(__rho_compiler_c "cl.exe")
      set(__rho_compiler_cxx "cl.exe")
    else()
      set(__rho_compiler_c "cc")
      set(__rho_compiler_cxx "c++")
    endif()
  endif()
endif()

__rho_compiler_type(
  __rho_compiler_cxx_vendor
  __rho_compiler_cxx_arch
  "${__rho_compiler_cxx}"
  "${__rho_compiler_cxx_flags}")
__rho_compiler_type(
  __rho_compiler_c_vendor
  __rho_compiler_c_arch
  "${__rho_compiler_c}"
  "${__rho_compiler_c_flags}")

if(NOT __rho_compiler_cxx_vendor STREQUAL __rho_compiler_c_vendor)
  __rho_block_message(
    "Your C and C++ compilers are different vendors; this is unsupported."
    "Your C compiler is ${__rho_compiler_c_vendor}, while your C++ compiler is ${__rho_compiler_cxx_vendor}"
    "Note: path to C compiler: ${__rho_compiler_c} ${__rho_compiler_c_flags}"
    "Note: path to C++ compiler: ${__rho_compiler_cxx} ${__rho_compiler_cxx_flags}")
  message(FATAL_ERROR "Distinct C and C++ compilers")
endif()
if(NOT __rho_compiler_cxx_arch STREQUAL __rho_compiler_c_arch)
  __rho_block_message(
    "Your C and C++ compilers have different architectures; this is unsupported."
    "Your C compiler is ${__rho_compiler_c_arch}, while your C++ compiler is ${__rho_compiler_cxx_arch}"
    "Note: C compiler: ${__rho_compiler_c} ${__rho_compiler_c_flags}"
    "Note: C++ compiler: ${__rho_compiler_cxx} ${__rho_compiler_cxx_flags}")
  message(FATAL_ERROR "Distinct C and C++ compiler architectures")
endif()

if(RHO_TARGET_COMPILER STREQUAL "default")
  set(RHO_TARGET_COMPILER "${__rho_compiler_cxx_vendor}"
    CACHE STRING "The compiler vendor" FORCE)
elseif(NOT RHO_TARGET_COMPILER STREQUAL __rho_compiler_cxx_vendor)
  __rho_block_message(
    "RHO_TARGET_COMPILER was set to an incorrect vendor."
    "Please set your CMAKE_C_COMPILER and CMAKE_CXX_COMPILER correctly."
    "RHO_TARGET_COMPILER: ${RHO_TARGET_COMPILER}"
    "C++ compiler vendor: ${__rho_compiler_cxx_vendor}"
    "Note: C++ compiler: ${__rho_compiler_cxx} ${__rho_compiler_cxx_flags}")
  message(FATAL_ERROR "Set RHO_TARGET_COMPILER incorrectly")
endif()

set(__rho_target_architecture_flag "")
if(__rho_compiler_cxx_vendor STREQUAL "clang")
  # clang is nice and lets us set our own target

  if(RHO_TARGET_ARCHITECTURE STREQUAL "default" AND WIN32)
    # on Windows, clang defaults to _host_ architecture, _not_ target architecture
    __rho_compiler_type(
      __rho_windows_cl_vendor # ignored
      __rho_windows_cl_arch
      "cl.exe"
      "")
    set(RHO_TARGET_ARCHITECTURE "${__rho_windows_cl_arch}"
      CACHE STRING "Architecture to compile for" FORCE)
  endif()

  if(RHO_TARGET_ARCHITECTURE STREQUAL "default")
    set(RHO_TARGET_ARCHITECTURE "${__rho_compiler_cxx_arch}"
      CACHE STRING "Architecture to compile for" FORCE)
  elseif(NOT __rho_compiler_cxx_arch STREQUAL RHO_TARGET_ARCHITECTURE)
    if(RHO_TARGET_ARCHITECTURE STREQUAL "x64")
      set(__rho_target_architecture_flag "--target=x86_64")
    elseif(RHO_TARGET_ARCHITECTURE STREQUAL "arm64")
      set(__rho_target_architecture_flag "--target=aarch64")
    elseif(RHO_TARGET_ARCHITECTURE STREQUAL "arm")
      set(__rho_target_architecture_flag "--target=armv7")
    elseif(RHO_TARGET_ARCHITECTURE STREQUAL "x86")
      set(__rho_target_architecture_flag "--target=i686")
    else()
      message(FATAL_ERROR "Unknown RHO_TARGET_ARCHITECTURE: ${RHO_TARGET_ARCHITECTURE}")
    endif()

    if(__rho_host_os STREQUAL "windows")
      set(__rho_target_architecture_flag "${__rho_target_architecture_flag}-pc-windows-msvc")
    elseif(__rho_host_os STREQUAL "linux")
      set(__rho_target_architecture_flag "${__rho_target_architecture_flag}-unknown-linux-gnu")
    elseif(__rho_host_os STREQUAL "osx")
      set(__rho_target_architecture_flag "${__rho_target_architecture_flag}-apple-darwin")
    else()
      message(FATAL_ERROR "Internal error: unknown __rho_host_os ${__rho_host_os}")
    endif()
  endif()
elseif(RHO_TARGET_ARCHITECTURE STREQUAL "default")
  set(RHO_TARGET_ARCHITECTURE "${__rho_compiler_cxx_arch}"
    CACHE STRING "Architecture to compile for" FORCE)
elseif(RHO_TARGET_ARCHITECTURE STREQUAL "x86" AND __rho_compiler_cxx_arch STREQUAL "x64" AND __rho_compiler_cxx_vendor STREQUAL "gcc")
  set(__rho_target_architecture_flag "-m32")
elseif(NOT RHO_TARGET_ARCHITECTURE STREQUAL __rho_compiler_cxx_arch)
  __rho_block_message(
    "RHO_TARGET_ARCHITECTURE was set to an incorrect architecture."
    "We cannot change the architecture of the compiler for ${__rho_compiler_cxx_vendor}."
    "Please choose a different compiler if you want to build for ${RHO_TARGET_ARCHITECTURE},"
    "or use a different developer command prompt."
    "RHO_TARGET_ARCHITECTURE: ${RHO_TARGET_ARCHITECTURE}"
    "Compiler architecture: ${__rho_compiler_cxx_arch}"
    "Note: C++ compiler: ${__rho_compiler_cxx} ${__rho_compiler_cxx_flags}")
  message(FATAL_ERROR "Set RHO_TARGET_ARCHITECTURE incorrectly")
endif()

find_program(__rho_compiler_c_full_path
  NAMES "${__rho_compiler_c}")
find_program(__rho_compiler_cxx_full_path
  NAMES "${__rho_compiler_cxx}")

set(__rho_target_architecture_flag "${__rho_target_architecture_flag}" CACHE STRING
  "The flag to pass to the compiler to get the architecture correct"
  FORCE)
set(CMAKE_C_COMPILER "${__rho_compiler_c_full_path}"
  CACHE STRING "Path to the C compiler" FORCE)
set(CMAKE_CXX_COMPILER "${__rho_compiler_cxx_full_path}"
  CACHE STRING "Path to the C++ compiler" FORCE)

if(NOT __rho_target_architecture_flag STREQUAL "")
  __rho_add_flag(CMAKE_C_FLAGS "${__rho_target_architecture_flag}")
  __rho_add_flag(CMAKE_CXX_FLAGS "${__rho_target_architecture_flag}")

  if(__rho_host_os STREQUAL "osx")
    if(RHO_TARGET_ARCHITECTURE STREQUAL "x64")
      set(CMAKE_OSX_ARCHITECTURES "x86_64" CACHE INTERNAL "")
    elseif(RHO_TARGET_ARCHITECTURE STREQUAL "arm64")
      set(CMAKE_OSX_ARCHITECTURES "arm64" CACHE INTERNAL "")
    else()
      message(FATAL_ERROR "RHO_TARGET_ARCHITECTURE must be either x64 or arm64 on macOS (was ${RHO_TARGET_ARCHITECTURE})")
    endif()
  endif()
endif()

if(RHO_TARGET_CXX_STDLIB STREQUAL "default")
  # do nothing
elseif(RHO_TARGET_CXX_STDLIB STREQUAL "libc++")
  if(NOT __rho_compiler_cxx_vendor STREQUAL "clang")
    message(FATAL_ERROR "Setting the standard library is unsupported for ${__rho_compiler_cxx_vendor}")
  endif()

  __rho_add_flag(CMAKE_CXX_FLAGS -stdlib=libc++)
  __rho_add_flag(CMAKE_EXE_LINKER_FLAGS -stdlib=libc++)
  __rho_add_flag(CMAKE_EXE_LINKER_FLAGS -lc++-abi)
  __rho_add_flag(CMAKE_SHARED_LINKER_FLAGS -stdlib=libc++)
  __rho_add_flag(CMAKE_SHARED_LINKER_FLAGS -lc++-abi)
else()
  message(FATAL_ERROR "Unknown RHO_TARGET_CXX_STDLIB setting: ${RHO_TARGET_CXX_STDLIB}")
endif()

message(STATUS "C++ Compiler: ${CMAKE_CXX_COMPILER} ${__rho_target_architecture_flag}")
message(STATUS "  (${__rho_compiler_cxx_vendor} for ${RHO_TARGET_ARCHITECTURE})")
