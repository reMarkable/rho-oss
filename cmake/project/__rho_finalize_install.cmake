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

set(__rho_project_config_in_file "" CACHE INTERNAL "Path to the project's -config.in file")
set(__rho_project_skip_install "" CACHE INTERNAL "Whether to skip the install step")

set(__rho_install_libs "" CACHE INTERNAL "The non-default library targets to install")
set(__rho_install_exes "" CACHE INTERNAL "The executable targets to install")
set(__rho_install_find_packages "" CACHE INTERNAL "The dependencies to find")

set(__rho_install_default_config_in_file "${CMAKE_CURRENT_LIST_DIR}/../misc/default-config.cmake.in")

# called as part of a DIRECTORY DEFER
function(__rho_finalize_install)
  if(__rho_project_skip_install)
    return()
  endif()

  # install targets
  string(REPLACE "::" "-" config_name "${PROJECT_NAME}")
  rho_vcpkg_json(VERSION proj_version)
  if(NOT DEFINED proj_version AND DEFINED PROJECT_VERSION)
    set(proj_version "${PROJECT_VERSION}")
  elseif(DEFINED PROJECT_VERSION AND NOT proj_version VERSION_EQUAL PROJECT_VERSION)
    message("${__rho_warning}" "vcpkg version is not the same as the version passed to project(): ${proj_version} != ${PROJECT_VERSION}")
  endif()

  rho_project_info(DEFAULT_TARGET default_target_name)
  if("${__rho_install_libs}" STREQUAL "" AND "${__rho_install_exes}" STREQUAL "" AND NOT TARGET "${default_target_name}")
    message(STATUS "Project ${PROJECT_NAME} defines no targets to install; not installing")
    return()
  endif()

  rho_project_info(DEFAULT_TARGET_NAMESPACE default_target_ns)
  rho_project_info(TARGET_NAMESPACE target_ns)
  if(NOT TARGET "${default_target_name}" AND NOT "${__rho_install_libs}" STREQUAL "")
    add_library("${default_target_name}" INTERFACE)
    foreach(lib IN LISTS __rho_install_libs)
      get_target_property(lib_alias ${lib} EXPORT_NAME)
      target_link_libraries("${default_target_name}"
        INTERFACE "${target_ns}::${lib_alias}")
    endforeach()
  endif()

  if(TARGET "${default_target_name}")
    install(TARGETS "${default_target_name}"
      EXPORT "${config_name}-default-targets"
      FILE_SET HEADERS)
    install(EXPORT "${config_name}-default-targets"
      NAMESPACE "${default_target_ns}::"
      DESTINATION "${CMAKE_INSTALL_DATADIR}/${config_name}")
  endif()

  if(NOT "${__rho_install_libs}" STREQUAL "" OR NOT "${__rho_install_exes}" STREQUAL "")
    install(TARGETS ${__rho_install_libs} ${__rho_install_exes}
      EXPORT "${config_name}-targets"
      FILE_SET HEADERS)
    install(EXPORT "${config_name}-targets"
      NAMESPACE "${target_ns}::"
      DESTINATION "${CMAKE_INSTALL_DATADIR}/${config_name}")
  endif()

  if(NOT "${__rho_install_exes}" STREQUAL "" AND _RHO_IN_VCPKG)
    rho_project_info(BINARY_PREFIX binary_prefix)
    set(tools "")
    foreach(exe IN LISTS __rho_install_exes)
      get_target_property(tool "${exe}" OUTPUT_NAME)
      if(NOT tool)
        set(tool "${exe}") # if OUTPUT_NAME is not set, use the target name (as CMake does)
      endif()
      rho_list(APPEND tools "${tool}")
    endforeach()

    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/__rho_all_tools" "${tools}")
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/__rho_all_tools"
      DESTINATION "${CMAKE_INSTALL_DATADIR}")
  endif()

  if(NOT "${__rho_install_find_packages}" STREQUAL "")
    set(RHO_FIND_DEPENDENCIES "include(CMakeFindDependencyMacro)")
    foreach(pkg IN LISTS __rho_install_find_packages)
      set(RHO_FIND_DEPENDENCIES "${RHO_FIND_DEPENDENCIES}\nfind_dependency(${pkg})")
    endforeach()
  else()
    set(RHO_FIND_DEPENDENCIES "")
  endif()

  # install -config.cmake file
  set(config_in_file "${__rho_project_config_in_file}")
  if(config_in_file STREQUAL "")
    set(config_in_file "${__rho_install_default_config_in_file}")
  endif()

  set(CONFIG_NAME "${config_name}")
  set(RHO_INCLUDE_TARGETS_FILE "")
  if(NOT "${__rho_install_libs}" STREQUAL "" OR NOT "${__rho_install_exes}" STREQUAL "")
    set(RHO_INCLUDE_TARGETS_FILE "include(\"\${CMAKE_CURRENT_LIST_DIR}/${CONFIG_NAME}-targets.cmake\")")
  endif()
  if(TARGET "${default_target_name}")
    set(RHO_INCLUDE_TARGETS_FILE "${RHO_INCLUDE_TARGETS_FILE}\ninclude(\"\${CMAKE_CURRENT_LIST_DIR}/${CONFIG_NAME}-default-targets.cmake\")")
  endif()

  configure_package_config_file("${config_in_file}"
    "${CMAKE_CURRENT_BINARY_DIR}/${config_name}-config.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_DATADIR}/${config_name}"
    NO_SET_AND_CHECK_MACRO)

  set(config_files_to_install "${CMAKE_CURRENT_BINARY_DIR}/${config_name}-config.cmake")

  if(NOT DEFINED proj_version)
    message("${__rho_warning}" "Failed to find a project version - please make sure you have a vcpkg.json with a version field, or set a project version in your `project()` call.")
  else()
    write_basic_package_version_file(
      "${CMAKE_CURRENT_BINARY_DIR}/${config_name}-config-version.cmake"
      VERSION "${proj_version}"
      COMPATIBILITY SameMajorVersion)
    list(APPEND config_files_to_install "${CMAKE_CURRENT_BINARY_DIR}/${config_name}-config-version.cmake")
  endif()

  install(
    FILES
      ${config_files_to_install}
    DESTINATION
      "${CMAKE_INSTALL_DATADIR}/${config_name}")

  rho_vcpkg_json(NAME vcpkg_name)
  if(_RHO_IN_VCPKG AND TARGET "${default_target_name}")
    file(WRITE "${CMAKE_CURRENT_BINARY_DIR}/usage"
"${vcpkg_name} provides CMake targets:

    find_package(${config_name} CONFIG REQUIRED)
    target_link_libraries(main PRIVATE ${default_target_ns}::${default_target_name})
")
    install(FILES "${CMAKE_CURRENT_BINARY_DIR}/usage"
      DESTINATION "${CMAKE_INSTALL_DATADIR}/${config_name}")
  endif()
endfunction()

