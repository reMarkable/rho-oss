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

set(_RHO_BOOT_FILE "${CMAKE_CURRENT_LIST_FILE}")

set(__rho_current_major "rel/0.5")

if(DEFINED RHO_DIRECTORY OR DEFINED ENV{RHO_DIRECTORY})
  if(NOT DEFINED RHO_DIRECTORY)
    message(STATUS "rho: Taking RHO_DIRECTORY from environment - $ENV{RHO_DIRECTORY}")
    set(RHO_DIRECTORY "$ENV{RHO_DIRECTORY}" CACHE INTERNAL "Location of the rho code")
  endif()

  include("${RHO_DIRECTORY}/rho.cmake")
  return()
endif()

block()
  set(__rho_directory "${CMAKE_BINARY_DIR}/rho")

  if(NOT DEFINED RHO_VERSION)
    if(DEFINED ENV{RHO_VERSION})
      message(STATUS "rho: Taking RHO_VERSION from environment - $ENV{RHO_VERSION}")
      set(RHO_VERSION "$ENV{RHO_VERSION}")
    else()
      set(RHO_VERSION "${__rho_current_major}")
    endif()
  endif()
  if(NOT DEFINED RHO_REPOSITORY)
    set(RHO_REPOSITORY "https:://github.com/reMarkable/rho-oss")
  endif()

  # Git code is copied and modified from __rho_git.cmake
  # rm-build code is copied and modified from RhoCMakeHelpers.cmake

  # __rho_git_acquire_lock(__rho_git_directory rho)
  #   uses __rho_git_get_location, __rho_get_cache_dir
  # set(__rho_git_directory "${__rho_git_directory}" CACHE INTERNAL "")
  # note: __rho_git_directory is used in RhoBootUpdate.cmake
  if(DEFINED ENV{RHO_CACHE_DIR})
    set(__rho_git_directory "$ENV{RHO_CACHE_DIR}/rho-git_rho")
  elseif(WIN32)
    set(__rho_git_directory "$ENV{LOCALAPPDATA}/rho/cache/rho-git_rho")
  else()
    set(__rho_git_directory "$ENV{HOME}/.cache/rho/rho-git_rho")
  endif()
  set(__rho_git_directory "${__rho_git_directory}" CACHE INTERNAL "")

  file(LOCK "${__rho_git_directory}"
    DIRECTORY
    TIMEOUT 5
    RESULT_VARIABLE rho_git_lock)
  if(NOT rho_git_lock EQUAL "0")
    message(FATAL_ERROR "Error locking rho git directory (${__rho_git_directory}) - try waiting for your other build to finish, then try again")
  endif()

  # __rho_git_initialize(URL "${RHO_REPOSITORY}" LOCK "${__rho_git_directory}")
  execute_process(
    COMMAND git -c init.defaultBranch=main init --bare -- "${__rho_git_directory}"
    OUTPUT_QUIET)
  execute_process(
    COMMAND git -C "${__rho_git_directory}" remote add origin "${RHO_REPOSITORY}"
    OUTPUT_QUIET
    ERROR_QUIET)
  execute_process(
    COMMAND git -C "${__rho_git_directory}" remote set-url origin "${RHO_REPOSITORY}"
    OUTPUT_QUIET
    ERROR_QUIET)

  # __rho_git_get_sha_for_ref(rev_parse LOCK "${__rho_git_directory}" REF "${RHO_VERSION}")
  foreach(attempt RANGE 1 5)
    execute_process(
      COMMAND git -C "${__rho_git_directory}" fetch --prune --prune-tags --force --tags origin
      RESULT_VARIABLE fetch_res
      OUTPUT_VARIABLE fetch_err
      ERROR_VARIABLE fetch_err)

    if(fetch_res EQUAL "0")
      break()
    endif()
  endforeach()

  if(NOT fetch_res EQUAL "0")
    message("rho: failed to fetch remote, going forward on best effort; see error message:")
    message("${fetch_err}")
    message(WARNING "failure to fetch remote")
  endif()

  # ignore the fact that we might have a tag or branch with a 40-character sha
  if(EXISTS "${__rho_git_directory}/refs/remotes/origin/${RHO_VERSION}")
    set(rev_to_parse "refs/remotes/origin/${RHO_VERSION}")
  elseif(EXISTS "${__rho_git_directory}/refs/tags/${RHO_VERSION}")
    set(rev_to_parse "refs/tags/${RHO_VERSION}")
  else()
    set(rev_to_parse "${RHO_VERSION}")
  endif()

  execute_process(
    COMMAND git -C "${__rho_git_directory}" rev-parse "${rev_to_parse}"
    RESULT_VARIABLE rev_parse_res
    OUTPUT_VARIABLE rev_parse
    ERROR_VARIABLE rev_parse_err)
  if(NOT rev_parse_res EQUAL "0")
    message("Could not find revision ${RHO_VERSION} at URL ${arg_URL}")
    message("Attempted to read ${rev_to_parse}")
    message("Error message was:")
    message("${rev_parse_err}")
    message(FATAL_ERROR "failed to find revision")
  endif()
  string(STRIP "${rev_parse}" rev_parse)

  # __rho_git_checkout_tree_to(LOCK "${__rho_git_directory}" SHA "${rev_parse}" DIRECTORY "${__rho_directory}")
  if(EXISTS "${__rho_directory}.tmp")
    file(REMOVE_RECURSE "${__rho_directory}.tmp")
  endif()
  file(MAKE_DIRECTORY "${__rho_directory}.tmp")
  execute_process(
    COMMAND git -C "${__rho_git_directory}" archive --format=tar  "--output=${__rho_directory}.tar" "${rev_parse}"
    RESULT_VARIABLE archive_res
    OUTPUT_QUIET
    ERROR_VARIABLE archive_error)

  if(NOT archive_res EQUAL "0")
    message("rho: Failed to archive reference ${rev_parse}:\n${archive_error}")
    message(FATAL_ERROR "failure to get reference")
  endif()

  file(LOCK "${__rho_git_directory}"
    DIRECTORY
    RELEASE)

  execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar xf "${__rho_directory}.tar"
    WORKING_DIRECTORY "${__rho_directory}.tmp")
  if(EXISTS "${__rho_directory}")
    file(REMOVE_RECURSE "${__rho_directory}")
  endif()
  file(RENAME "${__rho_directory}.tmp" "${__rho_directory}")

  set(RHO_DIRECTORY "${__rho_directory}" CACHE INTERNAL "Location of the rho code")
endblock()

include("${RHO_DIRECTORY}/rho.cmake")
