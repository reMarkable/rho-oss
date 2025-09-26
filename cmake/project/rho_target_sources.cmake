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

if(NOT __RHO_PROJECT_INCLUDE)
  message(FATAL_ERROR "You have included ${CMAKE_CURRENT_LIST_FILE} by itself. This is not supported.")
endif()

function(rho_target_sources target)
  rho_parse_arguments(POSITIONAL_ARGS 1
    SINGLE_ARGS
      # if called from rho_add_library or rho_add_executable
      __RHO_INTERNAL_FUNCTION_NAME
      INCLUDE_BASE SOURCE_BASE
    MULTI_ARGS
      INCLUDES SOURCES)

  if(NOT TARGET "${target}")
    message(FATAL_ERROR "Cannot specify sources for target \"${target}\" which is not built by this project.")
  endif()

  if(DEFINED arg___RHO_INTERNAL_FUNCTION_NAME)
    set(fname "${arg___RHO_INTERNAL_FUNCTION_NAME}")
  else()
    set(fname "${CMAKE_CURRENT_FUNCTION}")
  endif()

  get_property(target_type TARGET "${target}" PROPERTY TYPE)
  if(DEFINED arg_SOURCES OR DEFINED arg_SOURCE_BASE)
    rho_forward_arguments(MULTI_ARGS
      BASE_DIRS=arg_SOURCE_BASE
      FILES=arg_SOURCES)
    __rho_collect_files(sources
      FUNCTION_NAME "${fname}"
      ${param_BASE_DIRS}
      ${param_FILES})

    if(NOT "${sources}" STREQUAL "")
      target_sources("${target}" PRIVATE ${sources})
      rho_list(APPEND CACHE{__rho_project_sources_to_format} ${sources})
    endif()
  endif()

  if(DEFINED arg_INCLUDES OR DEFINED arg_INCLUDE_BASE)
    set(publicity PUBLIC)
    if(target_type STREQUAL "INTERFACE_LIBRARY")
      set(publicity INTERFACE)
    endif()

    rho_forward_arguments(MULTI_ARGS
      BASE_DIRS=arg_INCLUDE_BASE
      FILES=arg_INCLUDES)
    __rho_collect_files(includes
      FUNCTION_NAME "${fname}"
      ${param_BASE_DIRS}
      ${param_FILES})

    if(NOT "${includes}" STREQUAL "")
      target_sources("${target}"
        "${publicity}"
          FILE_SET HEADERS
          ${param_BASE_DIRS}
          FILES ${includes})
      rho_list(APPEND CACHE{__rho_project_sources_to_format} ${includes})
    endif()
  endif()
endfunction()

function(__rho_collect_files out)
  rho_parse_arguments(POSITIONAL_ARGS 1
    SINGLE_ARGS
      # for error messages
      FUNCTION_NAME
    MULTI_ARGS
      BASE_DIRS
      FILES
    REQUIRED_ARGS
      FUNCTION_NAME)

  set(base_files "")
  foreach(base IN LISTS arg_BASE_DIRS)
    cmake_path(ABSOLUTE_PATH base BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" NORMALIZE)
    if(NOT IS_DIRECTORY "${base}")
      message(FATAL_ERROR "${arg_FUNCTION_NAME}: non-directory \"${base}\" passed as a base")
    endif()

    cmake_path(APPEND base "*" OUTPUT_VARIABLE base_glob)
    file(GLOB_RECURSE cur_base_files
      LIST_DIRECTORIES false
      CONFIGURE_DEPENDS
      "${base_glob}")
    rho_list(APPEND base_files ${cur_base_files})
  endforeach()

  if(NOT DEFINED arg_FILES)
    set("${out}" "${base_files}" PARENT_SCOPE)
    return()
  endif()

  set(use_base_files 1)
  set(all_files "")

  rho_list(LENGTH len arg_FILES)
  set(index 0)
  while(index LESS len)
    rho_list(GET el arg_FILES "${index}")

    set(skip 0)
    if(el STREQUAL "SKIP")
      set(skip 1)
      math(EXPR index "${index} + 1")

      if(index EQUAL len)
        message(FATAL_ERROR "${arg_FUNCTION_NAME}: SKIP argument not passed a path")
      endif()
      rho_list(GET el arg_FILES "${index}")
    endif()

    if(NOT skip)
      set(use_base_files 0)
    endif()

    cmake_path(ABSOLUTE_PATH el BASE_DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}" NORMALIZE)
    if(EXISTS "${el}" AND NOT IS_DIRECTORY "${el}")
      set(el_files "${el}")
    else()
      if(IS_DIRECTORY "${el}")
        cmake_path(APPEND el "*")
      endif()
      file(GLOB_RECURSE el_files
        LIST_DIRECTORIES false
        CONFIGURE_DEPENDS
        "${el}")
    endif()

    if(skip)
      list(REMOVE_ITEM all_files ${el_files})
      list(REMOVE_ITEM base_files ${el_files})
    else()
      rho_list(APPEND all_files ${el_files})
    endif()

    math(EXPR index "${index} + 1")
  endwhile()

  if(use_base_files)
    set(all_files "${base_files}")
  endif()

  set("${out}" "${all_files}" PARENT_SCOPE)
endfunction()

