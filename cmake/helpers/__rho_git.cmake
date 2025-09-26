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

# This file's functions are included in modified form in rho-boot.cmake;
# if you modify them here, please update them in rho-boot also if necessary.
if(NOT __RHO_CMAKE_HELPERS_INCLUDE)
  message(FATAL_ERROR "You have included ${CMAKE_CURRENT_LIST_FILE} by itself. This is not supported.")
endif()

function(__rho_git_get_location out repo_name)
  __rho_get_cache_dir(rho_cache)
  set("${out}" "${rm_build}/rho-git_${repo_name}" PARENT_SCOPE)
endfunction()
macro(__rho_git_acquire_lock out repo_name)
  __rho_git_get_location(__rho_git_acquire_lock_dir "${repo_name}")

  file(LOCK "${__rho_git_acquire_lock_dir}"
    DIRECTORY
    GUARD FUNCTION
    TIMEOUT 5
    RESULT_VARIABLE __rho_git_acquire_lock)
  if(NOT __rho_git_acquire_lock STREQUAL "0")
    message(FATAL_ERROR "Error locking ${repo_name} git directory (${__rho_git_acquire_lock}) - try waiting for your other build to finish, then try again")
  endif()
  set("${out}" "${__rho_git_acquire_lock_dir}")
endmacro()

function(__rho_git_initialize)
  rho_parse_arguments(
    SINGLE_ARGS LOCK URL
    REQUIRED_ARGS LOCK URL)

  execute_process(
    COMMAND git init --bare -- "${arg_LOCK}"
    OUTPUT_QUIET)
  execute_process(
    COMMAND git -C "${arg_LOCK}" remote add origin "${arg_URL}"
    OUTPUT_QUIET
    ERROR_QUIET)
  execute_process(
    COMMAND git -C "${arg_LOCK}" remote set-url origin "${arg_URL}"
    OUTPUT_QUIET
    ERROR_QUIET)
endfunction()

string(REPEAT "[a-fA-F0-9]" 40 __rho_git_sha_regex)
set(__rho_git_sha_regex "^${__rho_git_sha_regex}$")

function(__rho_git_get_sha_for_ref out_sha)
  rho_parse_arguments(
    POSITIONAL_ARGS 1
    SINGLE_ARGS LOCK REF
    REQUIRED_ARGS LOCK REF)

  foreach(attempt RANGE 1 5)
    execute_process(
      COMMAND git -C "${arg_LOCK}" fetch -p origin
      RESULT_VARIABLE fetch_res
      OUTPUT_VARIABLE fetch_err
      ERROR_VARIABLE fetch_err)

    if(fetch_res EQUAL "0")
      break()
    endif()
  endforeach()

  if(NOT fetch_res EQUAL "0")
    __rho_block_message(
      "rho: failed to fetch remote (${fetch_res});"
      "going forward on best effort; see error message:"
      "${fetch_err}")
    message(WARNING "failure to fetch remote")
  endif()

  execute_process(
    COMMAND git -C "${arg_LOCK}" fetch --tags -f origin
    RESULT_VARIABLE fetch_tag_res
    OUTPUT_VARIABLE fetch_tag_err
    ERROR_VARIABLE fetch_tag_err)

  if(NOT fetch_tag_res EQUAL "0")
    __rho_block_message(
      "rho: failed to fetch tags from remote (${fetch_tag_res});"
      "going forward on best effort; see error message:"
      "${fetch_tag_err}")
    message(WARNING "failure to fetch remote tags")
  endif()

  if(arg_REF MATCHES "${__rho_git_sha_regex}")
    # check if the ref exists, since rev-parse given a 40-character sha
    # just gives you back the same thing; it does not check for the existence
    # of that sha
    execute_process(
      COMMAND git -C "${arg_LOCK}" cat-file -t -- "${arg_REF}"
      RESULT_VARIABLE cat_file_res
      OUTPUT_QUIET
      ERROR_VARIABLE cat_file_err)
    if(NOT cat_file_res EQUAL "0")
      __rho_block_message(
        "Could not find SHA ${arg_REF} in the repository:"
        "${cat_file_err}")
      message(FATAL_ERROR "could not find sha")
    endif()

    set("${out_sha}" "${arg_REF}" PARENT_SCOPE)
    return()
  elseif(EXISTS "${arg_LOCK}/refs/remotes/origin/${arg_REF}")
    set(rev_to_parse "refs/remotes/origin/${arg_REF}")
  elseif(EXISTS "${arg_LOCK}/refs/tags/${arg_REF}")
    set(rev_to_parse "refs/tags/${arg_REF}")
  else()
    set(rev_to_parse "${arg_REF}")
  endif()

  execute_process(
    COMMAND git -C "${arg_LOCK}" rev-parse "${rev_to_parse}"
    RESULT_VARIABLE rev_parse_res
    OUTPUT_VARIABLE rev_parse
    ERROR_VARIABLE rev_parse_err)
  if(NOT rev_parse_res EQUAL "0")
    __rho_block_message(
      "Could not find revision ${arg_REF} at URL ${arg_URL}"
      "Attempted to read ${rev_to_parse}"
      "Error message was:"
      "${rev_parse_err}")
    message(FATAL_ERROR "failed to find revision")
  endif()

  string(STRIP "${rev_parse}" rev_parse)
  set("${out_sha}" "${rev_parse}" PARENT_SCOPE)
endfunction()

function(__rho_git_checkout_worktree_to)
  rho_parse_arguments(
    SINGLE_ARGS LOCK SHA DIRECTORY
    REQUIRED_ARGS LOCK SHA DIRECTORY)

  if(NOT "${arg_SHA}" MATCHES "${__rho_git_sha_regex}")
    message(FATAL_ERROR "Invalid argument to SHA: must be a 40-character git sha: ${arg_SHA}")
  endif()

  execute_process(
    COMMAND git -C "${arg_LOCK}" worktree add --detach "${arg_DIRECTORY}" "${arg_SHA}"
    RESULT_VARIABLE worktree_res
    OUTPUT_QUIET
    ERROR_VARIABLE worktree_error)

  if(NOT worktree_res EQUAL "0")
    __rho_block_message(
      "rho: Failed to create a worktree for reference ${arg_SHA}"
      "  in directory ${arg_DIRECTORY}:"
      "${worktree_error}")
    file(REMOVE_RECURSE "${arg_DIRECTORY}")
    message(FATAL_ERROR "failure to create worktree")
  endif()
endfunction()

# gets the actual tree at the commit, without being a git repository
function(__rho_git_checkout_tree_to)
  rho_parse_arguments(
    SINGLE_ARGS LOCK SHA DIRECTORY
    REQUIRED_ARGS LOCK SHA DIRECTORY)

  if(NOT "${arg_SHA}" MATCHES "${__rho_git_sha_regex}")
    message(FATAL_ERROR "Invalid argument to SHA: must be a 40-character git sha: ${arg_SHA}")
  endif()

  if(EXISTS "${arg_DIRECTORY}")
    file(REMOVE_RECURSE "${arg_DIRECTORY}.tmp")
  endif()
  file(MAKE_DIRECTORY "${arg_DIRECTORY}.tmp")
  execute_process(
    COMMAND git -C "${arg_LOCK}" archive --format=tar  "--output=${arg_DIRECTORY}.tar" "${arg_SHA}"
    RESULT_VARIABLE archive_res
    OUTPUT_QUIET
    ERROR_VARIABLE archive_error)

  if(NOT archive_res EQUAL "0")
    __rho_block_message(
      "rho: Failed to archive reference ${arg_SHA}"
      "${archive_error}")
    message(FATAL_ERROR "failure to get reference")
  endif()

  execute_process(
    COMMAND ${CMAKE_COMMAND} -E tar xf "${arg_DIRECTORY}.tar"
    WORKING_DIRECTORY "${arg_DIRECTORY}.tmp")
  if(EXISTS "${arg_DIRECTORY}")
    file(REMOVE_RECURSE "${arg_DIRECTORY}")
  endif()
  file(RENAME "${arg_DIRECTORY}.tmp" "${arg_DIRECTORY}")
endfunction()
