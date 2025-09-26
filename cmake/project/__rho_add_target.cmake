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

include(GenerateExportHeader)

function(rho_add_executable target)
  cmake_parse_arguments(PARSE_ARGV 1 arg "" "" "")
  __rho_add_target(executable "${target}" ${arg_UNPARSED_ARGUMENTS})
endfunction()
function(rho_add_library target)
  cmake_parse_arguments(PARSE_ARGV 1 arg "" "" "")
  __rho_add_target(library "${target}" ${arg_UNPARSED_ARGUMENTS})
endfunction()

function(__rho_add_target type target)
  rho_parse_arguments(POSITIONAL_ARGS 2
    OPTION_ARGS
      INTERFACE
      SKIP_INSTALL
      SKIP_COMMON_FLAGS
      SKIP_AUTO_BASES
    SINGLE_ARGS
      INCLUDE_BASE SOURCE_BASE
      OUTPUT_NAME
      INTERNAL_TARGET_NAME
    MULTI_ARGS
      INCLUDES SOURCES
      ENABLED_MSVC_WARNING_FLAGS ENABLED_GNU_WARNING_FLAGS
      DISABLED_MSVC_WARNING_FLAGS DISABLED_GNU_WARNING_FLAGS)

  if(NOT target MATCHES "^([a-z0-9]+[-_])*[a-z0-9]+$")
    message(FATAL_ERROR "rho_add_${type}: invalid target name \"${target}\" (expected an alphanumeric string separated by - or _)")
  endif()
  if(NOT DEFINED arg_INTERNAL_TARGET_NAME)
    set(arg_INTERNAL_TARGET_NAME "${target}")
  endif()


  rho_project_info(DEFAULT_TARGET default_target)
  if(target STREQUAL default_target)
    rho_project_info(DEFAULT_TARGET_NAMESPACE namespace)
  else()
    rho_project_info(TARGET_NAMESPACE namespace)
  endif()

  string(REPLACE "-" "::" target_alias "${target}")

  if(type STREQUAL "executable")
    if(arg_INTERFACE)
      message(FATAL_ERROR "rho_add_executable: executables may not be INTERFACE")
    endif()
    add_executable("${arg_INTERNAL_TARGET_NAME}")
    add_executable("${namespace}::${target_alias}" ALIAS "${arg_INTERNAL_TARGET_NAME}")
  else()
    rho_forward_arguments(OPTION_ARGS INTERFACE)
    add_library("${arg_INTERNAL_TARGET_NAME}" ${param_INTERFACE})
    add_library("${namespace}::${target_alias}" ALIAS "${arg_INTERNAL_TARGET_NAME}")
  endif()

  set_target_properties("${arg_INTERNAL_TARGET_NAME}"
    PROPERTIES
      EXPORT_NAME "${target_alias}")

  if(arg_INTERFACE)
    if(DEFINED arg_OUTPUT_NAME)
      message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: ${target} is an INTERFACE library, and therefore does not have an output name")
    endif()
  else()
    rho_project_info(BINARY_PREFIX binary_prefix)
    rho_project_info(INCLUDE_BASE include_dir)

    if(NOT DEFINED arg_OUTPUT_NAME)
      set(arg_OUTPUT_NAME "${binary_prefix}-${target}")
    endif()

    set_target_properties("${arg_INTERNAL_TARGET_NAME}"
      PROPERTIES
        OUTPUT_NAME "${arg_OUTPUT_NAME}")

    set(export_file_dir "${CMAKE_CURRENT_BINARY_DIR}/include/${include_dir}")
    set(export_base_name "${binary_prefix}")
    if(NOT target STREQUAL default_target)
      string(REPLACE "-" "/" target_export_file_dir "${target}")
      set(export_file_dir "${export_file_dir}/${target_export_file_dir}")
      set(export_base_name "${export_base_name}_${target}")
    endif()

    if(NOT type STREQUAL "executable")
      generate_export_header(${arg_INTERNAL_TARGET_NAME}
        BASE_NAME "${export_base_name}"
        EXPORT_FILE_NAME "${export_file_dir}/export_macro.h")

      rho_target_sources("${arg_INTERNAL_TARGET_NAME}"
        INCLUDE_BASE "${CMAKE_CURRENT_BINARY_DIR}/include"
        INCLUDES "${export_file_dir}/export_macro.h")
    endif()
  endif()

  if(NOT arg_SKIP_AUTO_BASES)
    # note: CMAKE_CURRENT_LIST_DIR is the directory _of the file that calls this_
    if(NOT DEFINED arg_INCLUDE_BASE AND EXISTS "${CMAKE_CURRENT_LIST_DIR}/include")
      set(arg_INCLUDE_BASE "include")
    endif()
    if(NOT DEFINED arg_SOURCE_BASE AND EXISTS "${CMAKE_CURRENT_LIST_DIR}/src")
      set(arg_SOURCE_BASE "src")
    endif()
  endif()
  rho_forward_arguments(
    SINGLE_ARGS
      INCLUDE_BASE SOURCE_BASE
    MULTI_ARGS
      INCLUDES SOURCES)
  rho_target_sources("${arg_INTERNAL_TARGET_NAME}"
    ${param_INCLUDE_BASE}
    ${param_INCLUDES}
    ${param_SOURCE_BASE}
    ${param_SOURCES})

  if(NOT arg_SKIP_COMMON_FLAGS)
    rho_forward_arguments(MULTI_ARGS
      ENABLED_MSVC_WARNING_FLAGS ENABLED_GNU_WARNING_FLAGS
      DISABLED_MSVC_WARNING_FLAGS DISABLED_GNU_WARNING_FLAGS)
    rho_target_common_flags("${arg_INTERNAL_TARGET_NAME}"
      ${param_ENABLED_MSVC_WARNING_FLAGS} ${param_ENABLED_GNU_WARNING_FLAGS}
      ${param_DISABLED_MSVC_WARNING_FLAGS} ${param_DISABLED_GNU_WARNING_FLAGS})
  endif()
  if(NOT arg_SKIP_INSTALL)
    rho_install("${arg_INTERNAL_TARGET_NAME}")
  endif()
endfunction()
