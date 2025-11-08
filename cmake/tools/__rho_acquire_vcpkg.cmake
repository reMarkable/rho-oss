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

function(__rho_acquire_vcpkg out)
  rho_parse_arguments(
    POSITIONAL_ARGS 1
    SINGLE_ARGS REPO REF
    REQUIRED_ARGS REF)

  if(DEFINED RHO_VCPKG_ROOT)
    set(vcpkg_root "${RHO_VCPKG_ROOT}")
  else()
    __rho_get_cache_dir(rm_build)
    if(arg_REF MATCHES "${__rho_git_sha_regex}" AND EXISTS "${rm_build}/rho-vcpkg/${arg_REF}")
      set(vcpkg_root "${rm_build}/rho-vcpkg/${arg_REF}")
    else()
      if(NOT DEFINED arg_REPO)
        set(arg_REPO "https://github.com/microsoft/vcpkg")
      endif()

      message(STATUS "rho: acquiring vcpkg from ${arg_REPO} at ${arg_REF}")

      __rho_git_acquire_lock(git_lock vcpkg)
      __rho_git_initialize(
        LOCK "${git_lock}"
        URL "${arg_REPO}")
      __rho_git_get_sha_for_ref(sha
        LOCK "${git_lock}"
        REF "${arg_REF}")

      set(vcpkg_root "${rm_build}/rho-vcpkg/${sha}")
      __rho_git_checkout_worktree_to(
        LOCK "${git_lock}"
        SHA "${sha}"
        DIRECTORY "${vcpkg_root}")
    endif()
  endif()

  set(RHO_VCPKG_ROOT "${vcpkg_root}" CACHE STRING
    "The root of your vcpkg directory")

  if("${__rho_host_os}" STREQUAL "windows")
    set(__rho_vcpkg_exe "${vcpkg_root}/vcpkg.exe" CACHE INTERNAL "")
    set(bootstrap_cmd "${vcpkg_root}/bootstrap-vcpkg.bat")
  else()
    set(__rho_vcpkg_exe "${vcpkg_root}/vcpkg" CACHE INTERNAL "")
    set(bootstrap_cmd "${vcpkg_root}/bootstrap-vcpkg.sh")
  endif()

  if(NOT EXISTS "${__rho_vcpkg_exe}")
    message(STATUS "rho: bootstrapping vcpkg")
    execute_process(
      COMMAND ${bootstrap_cmd} -disableMetrics
      WORKING_DIRECTORY ${vcpkg_root}
      OUTPUT_VARIABLE bootstrap_out
      ERROR_VARIABLE bootstrap_out
      RESULT_VARIABLE bootstrap_res)

    if(NOT bootstrap_res EQUAL "0")
      __rho_block_message(
        "bootstrapping vcpkg failed with ${bootstrap_res}:"
        "${bootstrap_out}")
      message(FATAL_ERROR "rho: bootstrapping vcpkg - failed")
    endif()
    message(STATUS "rho: bootstrapping vcpkg - success")
  endif()

  if("${__rho_host_os}" STREQUAL "linux"
      AND "${__rho_host_architecture}" STREQUAL "arm64")
    # VCPKG_FORCE_SYSTEM_BINARIES must be set on "weird platforms", see
    # https://github.com/microsoft/vcpkg-tool/blob/1c9ec1978a6b0c2b39c9e9554a96e3e275f7556e/src/vcpkg.cpp#L277
    set(ENV{VCPKG_FORCE_SYSTEM_BINARIES} 1)
  endif()

  set("${out}" "${vcpkg_root}" PARENT_SCOPE)
endfunction()
