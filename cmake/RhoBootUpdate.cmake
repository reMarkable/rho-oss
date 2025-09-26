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
cmake_policy(VERSION 3.25)

if(NOT __rho_top_level_project)
  return()
endif()

# we are in the OSS version, don't print anything
return()

block()
  if(NOT DEFINED __rho_git_directory)
    # we didn't auto-download rho with rho-boot, so we shouldn't check for out-of-dateness
    return()
  endif()

  file(READ "${_RHO_BOOT_FILE}" project_rho_boot)
  file(READ "${CMAKE_CURRENT_LIST_DIR}/misc/rho-boot.cmake" rhos_rho_boot)

  # avoid warning when it's just weird whitespace stuff
  string(STRIP "${project_rho_boot}" project_rho_boot)
  string(STRIP "${rhos_rho_boot}" rhos_rho_boot)
  string(REPLACE "\r\n" "\n" "${project_rho_boot}" project_rho_boot)
  string(REPLACE "\r\n" "\n" "${rhos_rho_boot}" rhos_rho_boot)

  if(NOT project_rho_boot STREQUAL rhos_rho_boot)
    __rho_block_message(
      "The rho-boot.cmake you have in your project is out-of-date!"
      "Please do an update as soon as possible; just run:"
      "cp \"${CMAKE_CURRENT_LIST_DIR}/misc/rho-boot.cmake\" \"${_RHO_BOOT_FILE}\""
      "Thanks!!!")
    message(WARNING "rho-boot out of date!")
  endif()

  if(NOT project_rho_boot MATCHES [[set\(__rho_current_major "([^"]*)"\)]])
    # could not find major version; just ignore and move on
    message(STATUS "rho note: could not find current __rho_current_major, not warning about update")
    return()
  endif()
  set(project_rho_boot_major "${CMAKE_MATCH_1}")

  # now check for latest version
  set(release_rho_boot_path "refs/remotes/origin/release:cmake/misc/rho-boot.cmake")
  execute_process(
    COMMAND git -C "${__rho_git_directory}" show "${release_rho_boot_path}"
    RESULT_VARIABLE release_rho_boot_res
    OUTPUT_VARIABLE release_rho_boot
    ERROR_VARIABLE release_rho_boot_err)
  if(NOT release_rho_boot_res EQUAL "0")
    # could not find the release data; just ignore and move on
    message(STATUS "rho note: could not find release rho-boot (${release_rho_boot_res}), not warning about update")
    message("${release_rho_boot_err}")
    return()
  endif()

  if(NOT release_rho_boot MATCHES [[set\(__rho_current_major "([^"]*)"\)]])
    # could not find major version; just ignore and move on
    message(STATUS "rho note: could not find release __rho_current_major, not warning about update")
    return()
  endif()
  set(release_rho_boot_major "${CMAKE_MATCH_1}")

  if(NOT project_rho_boot_major STREQUAL release_rho_boot_major)
    __rho_block_message(
      "You are currently on an outdated major version of rho! You may want to update soon."
      "(your version: ${project_rho_boot_major}, current release: ${release_rho_boot_major})"
      "You can attempt an update with the following command:"
      ""
      "git -C \"${__rho_git_directory}\" show ${release_rho_boot_path} >\"${_RHO_BOOT_FILE}\""
      ""
      "If there are any problems, please let us know at ${__rho_github_issue}.")
    message(WARNING "rho on an out-of-date major version")
  endif()
endblock()
