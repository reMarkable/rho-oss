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

if(NOT __rho_top_level_project)
  return()
endif()
if(DEFINED CMAKE_TOOLCHAIN_FILE AND NOT __rho_standard_toolchain)
  # avoid installing this stuff when we have a custom toolchain already
  return()
endif()

# we check for using RhoTools by checking whether we have a toolchain file;
# however, we set the toolchain file inside RhoTools, so on reconfigure,
# we would otherwise not rerun RhoTools.
set(__rho_standard_toolchain ON CACHE INTERNAL
  "Make sure not to skip RhoTools on re-configure")

set(VCPKG_MANIFEST_DIR "${RHO_CURRENT_MANIFEST_DIR}")

if(NOT CMAKE_GENERATOR MATCHES "^Ninja")
  __rho_block_message(
    "For a myriad of reasons, rho does not support non-ninja generators."
    "You are using the generator: ${CMAKE_GENERATOR}."
    "Please pass -G Ninja or -G \"Ninja Multi-Config\" to your cmake invocation."
    "If you believe that we should support a different generator, please open an issue at:"
    "${__rho_github_issue}")
  message(FATAL_ERROR "Non-ninja generator")
endif()

cmake_host_system_information(RESULT __rho_host_is_64bit QUERY IS_64BIT)
if(NOT __rho_host_is_64bit)
  __rho_block_message(
    "Attempted to build on a 32-bit system; this is unsupported."
    "If on Windows, open a 64-bit developer command prompt."
    "Otherwise, if you believe this to be in error, please"
    "report this at ${__rho_github_issue}")
  message(FATAL_ERROR "Building on 32-bit")
endif()

if(CMAKE_HOST_SYSTEM_NAME STREQUAL "Darwin")
  set(__rho_host_os "osx")
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Linux")
  set(__rho_host_os "linux")
elseif(CMAKE_HOST_SYSTEM_NAME STREQUAL "Windows")
  set(__rho_host_os "windows")
else()
  __rho_block_message(
    "Unknown host operating system: \"${__rho_host_os}\"."
    "Please report this at ${__rho_github_issue}")
  message(FATAL_ERROR "Unknown host os")
endif()

# this should be cmake_host_system_information, but CMake _only_
# reads the cmake binary's platform, not the actual host platform
if(__rho_host_os STREQUAL "windows")
  if(DEFINED ENV{PROCESSOR_ARCHITEW6432})
    set(__rho_host_architecture "$ENV{PROCESSOR_ARCHITEW6432}")
  else()
    set(__rho_host_architecture "$ENV{PROCESSOR_ARCHITECTURE}")
  endif()
elseif(__rho_host_os STREQUAL "osx")
  execute_process(COMMAND sysctl -q hw.optional.arm64
    OUTPUT_VARIABLE sysctl_out
    ERROR_VARIABLE sysctl_err
    RESULT_VARIABLE sysctl_res)
  if(sysctl_res EQUAL "0" AND sysctl_out MATCHES [[hw\.optional\.arm64: 1]])
    set(__rho_host_architecture "arm64")
  else()
    cmake_host_system_information(RESULT __rho_host_architecture QUERY OS_PLATFORM)
  endif()
elseif(__rho_host_os STREQUAL "linux")
  cmake_host_system_information(RESULT __rho_host_architecture QUERY OS_PLATFORM)
endif()

if(__rho_host_architecture MATCHES "^(arm|aarch|ARM)")
  set(__rho_host_architecture "arm64")
elseif(__rho_host_architecture MATCHES "^(x86_64|AMD64)")
  set(__rho_host_architecture "x64")
else()
  __rho_block_message(
    "Unknown host cpu architecture: \"${__rho_host_architecture}\"."
    "Please report this at ${__rho_github_issue}")
  message(FATAL_ERROR "Unknown host architecture")
endif()

# Note for readers - RHO_TARGET is an internal thing we use to build for our
# (reMarkable) tablets; theoretically, it should at some point allow for the ability
# to cross-compile for stuff like Android and the like, which I hope to do.

# By default, RHO_TARGET will be "host", which, by default, builds for the host system
# (but allows you to customize all the things to get your own stuff)
# If RHO_TARGET is host (or unset), you can additionally set
# - RHO_TARGET_ARCHITECTURE to get a different target architecture
# - RHO_TARGET_COMPILER to get a different compiler

# allow setting as a non-cache variable
if(DEFINED RHO_TARGET)
  set(__rho_tmp "${RHO_TARGET}")
else()
  set(__rho_tmp "host")
endif()
set(RHO_TARGET "${__rho_tmp}" CACHE STRING "The target for rho to build for" FORCE)

if(DEFINED RHO_TARGET_ARCHITECTURE)
  set(__rho_tmp "${RHO_TARGET_ARCHITECTURE}")
else()
  set(__rho_tmp "default")
endif()
set(RHO_TARGET_ARCHITECTURE "${__rho_tmp}"
  CACHE STRING "Which architecture to build for - non-default values currently only supported on macOS or clang" FORCE)

if(DEFINED RHO_TARGET_COMPILER)
  set(__rho_tmp "${RHO_TARGET_COMPILER}")
else()
  set(__rho_tmp "default")
endif()
set(RHO_TARGET_COMPILER "${__rho_tmp}"
  CACHE STRING "Which compiler to use - non-default values currently only supported on Linux and Windows" FORCE)

if(DEFINED RHO_TARGET_CXX_STDLIB)
  set(__rho_tmp "${RHO_TARGET_CXX_STDLIB}")
else()
  set(__rho_tmp "default")
endif()
set(RHO_TARGET_CXX_STDLIB "${__rho_tmp}"
  CACHE STRING "Which standard library to use - a non-default value of libc++ is currently only supported on Linux with clang" FORCE)

if(DEFINED RHO_VCPKG_VERSION)
  set(__rho_tmp "${RHO_VCPKG_VERSION}")
else()
  set(__rho_tmp "${__rho_default_vcpkg_version}")
endif()
set(RHO_VCPKG_VERSION "${__rho_tmp}"
  CACHE STRING "Which vcpkg SHA to use when bootstrapping it." FORCE)

if(RHO_TARGET STREQUAL "host")
  option(BUILD_SHARED_LIBS "Build shared libraries" ON)
else()
  if(NOT RHO_TARGET_ARCHITECTURE STREQUAL "default" OR NOT RHO_TARGET_COMPILER STREQUAL "default")
    message(FATAL_ERROR "Non-default RHO_TARGET_ARCHITECTURE and RHO_TARGET_COMPILER is only supported on host builds")
  endif()
  option(BUILD_SHARED_LIBS "Build shared libraries" OFF)
endif()

# I have accidentally set this for my own builds, might as well check for them.
if(DEFINED RHO_COMPILER)
  message(FATAL_ERROR "Unknown variable RHO_COMPILER set - did you mean RHO_TARGET_COMPILER?")
endif()
if(DEFINED RHO_ARCHITECTURE)
  message(FATAL_ERROR "Unknown variable RHO_ARCHITECTURE set - did you mean RHO_TARGET_ARCHITECTURE?")
endif()

if(RHO_TARGET STREQUAL "host")
  set(__rho_toolset "default")

  include("${CMAKE_CURRENT_LIST_DIR}/tools/detect_compiler.cmake")

  if(__rho_host_os STREQUAL "osx")
    set(__rho_vcpkg_default_target_triplet "${RHO_TARGET_ARCHITECTURE}-osx")

    if(BUILD_SHARED_LIBS)
      set(__rho_vcpkg_default_target_triplet "${__rho_vcpkg_default_target_triplet}-dynamic")
    endif()
  elseif(__rho_host_os STREQUAL "windows")
    set(__rho_vcpkg_default_target_triplet "${RHO_TARGET_ARCHITECTURE}-windows")
    if(RHO_TARGET_COMPILER STREQUAL "clang")
      set(__rho_vcpkg_default_target_triplet "${__rho_vcpkg_default_target_triplet}-clang")
    elseif(RHO_TARGET_COMPILER STREQUAL "gcc")
      message(FATAL_ERROR "Building with gcc on Windows not yet supported.")
    endif()

    if(NOT BUILD_SHARED_LIBS)
      set(__rho_vcpkg_default_target_triplet "${__rho_vcpkg_default_target_triplet}-static-md")
    endif()
  elseif(__rho_host_os STREQUAL "linux")
    set(__rho_vcpkg_default_target_triplet "${RHO_TARGET_ARCHITECTURE}-linux")

    if(RHO_TARGET_COMPILER STREQUAL "clang")
      set(__rho_vcpkg_default_target_triplet "${__rho_vcpkg_default_target_triplet}-clang")
    endif()

    if(BUILD_SHARED_LIBS)
      set(__rho_vcpkg_default_target_triplet "${__rho_vcpkg_default_target_triplet}-dynamic")
    endif()
  endif()

else()
  message(FATAL_ERROR "Unknown RHO_TARGET (${RHO_TARGET}) - did you use a preset?")
endif()

if(NOT DEFINED CACHE{VCPKG_HOST_TRIPLET})
  set(VCPKG_HOST_TRIPLET "${__rho_host_architecture}-${__rho_host_os}"
      CACHE STRING "Auto detected vcpkg host triplet")
endif()

if(NOT DEFINED CACHE{VCPKG_TARGET_TRIPLET})
  set(VCPKG_TARGET_TRIPLET "${__rho_vcpkg_default_target_triplet}"
      CACHE STRING "Auto detected vcpkg target triplet")
endif()

if(NOT DEFINED CACHE{VCPKG_INSTALL_OPTIONS})
  set(VCPKG_INSTALL_OPTIONS "--no-print-usage"
    CACHE STRING "Avoid printing usage for vcpkg ports")
endif()

if(NOT (RHO_TARGET STREQUAL "host" AND __rho_host_architecture STREQUAL RHO_TARGET_ARCHITECTURE))
  set(__rho_crosscompiling ON CACHE INTERNAL "")
else()
  set(__rho_crosscompiling OFF CACHE INTERNAL "")
endif()

include("${CMAKE_CURRENT_LIST_DIR}/tools/__rho_acquire_vcpkg.cmake")

__rho_acquire_vcpkg(vcpkg_root
  REPO https://github.com/microsoft/vcpkg.git
  REF "${RHO_VCPKG_VERSION}")

if(__rho_host_os STREQUAL "linux" AND __rho_host_architecture STREQUAL "arm64")
  set(ENV{VCPKG_FORCE_SYSTEM_BINARIES} ON)
endif()

# Note: it might be a good idea to replace vcpkg.cmake, so that we no longer have to deal with their issues
set(CMAKE_TOOLCHAIN_FILE "${vcpkg_root}/scripts/buildsystems/vcpkg.cmake" CACHE INTERNAL "Path to vcpkg's cmake toolchain")

# We want to completely control the non-environment overlays
function(__rho_setup_overlays type)
  set(overlays_tmp "")
  if(DEFINED "VCPKG_OVERLAY_${type}")
    list(APPEND overlays_tmp "${VCPKG_OVERLAY_${type}}")
  endif()
  # just get all the extra arguments into a list
  cmake_parse_arguments(PARSE_ARGV 1 arg "" "" "")
  list(APPEND overlays_tmp "${arg_UNPARSED_ARGUMENTS}")

  set(overlays_absolute "")
  foreach(overlay IN LISTS overlays_tmp)
    cmake_path(ABSOLUTE_PATH overlay NORMALIZE)
    list(APPEND overlays_absolute "${overlay}")
  endforeach()
  list(REMOVE_DUPLICATES overlays_absolute)
  set("VCPKG_OVERLAY_${type}" "${overlays_absolute}" CACHE INTERNAL "")
endfunction()
__rho_setup_overlays(PORTS)
__rho_setup_overlays(TRIPLETS
  "${CMAKE_CURRENT_LIST_DIR}/tools/vcpkg_triplets"
  "${CMAKE_CURRENT_BINARY_DIR}/rho-generated/vcpkg_triplets")

if(NOT __rho_toolset STREQUAL "default")
  __rho_acquire("${__rho_toolset}"
    VCPKG_ROOT "${vcpkg_root}")
  set(toolchain_file "$CACHE{VCPKG_CHAINLOAD_TOOLCHAIN_FILE}")
  set(target_architecture "${RHO_TARGET_ARCHITECTURE}")
  configure_file(
    "${CMAKE_CURRENT_LIST_DIR}/tools/vcpkg_triplets/${__rho_toolset}.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/rho-generated/vcpkg_triplets/${__rho_vcpkg_default_target_triplet}.cmake"
    @ONLY)
endif()

