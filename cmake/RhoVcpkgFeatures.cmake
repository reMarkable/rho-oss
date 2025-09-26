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

block()

  if(DEVELOPER_MODE AND NOT __rho_crosscompiling)
    set(default_build_tests ON)
  else()
    set(default_build_tests OFF)
  endif()
  option(BUILD_TESTING "Whether to build tests" "${default_build_tests}")

  # This data is cached as `__rho_vcpkg_manifest_features` after the following if
  rho_vcpkg_json(FEATURES vcpkg_manifest_features)

  # In order to discover default featuers, we want:
  # - to be in DEVELOPER_MODE (otherwise, you must set features explicitly)
  # - not a subproject (same idea as when you're not in dev mode)
  # - to have used rho's built-in tool acquire mechanism with vcpkg
  # - to actually have features; if we don't have features, we don't have any default features
  # - to not have done this work already; if we know the default value for all
  #   of the features we know about, no reason to run this again
  set(discover_default_features 0)
  if(DEVELOPER_MODE AND __rho_top_level_project AND DEFINED __rho_vcpkg_exe AND NOT vcpkg_manifest_features STREQUAL "")
    if(NOT DEFINED __rho_vcpkg_manifest_features OR NOT vcpkg_manifest_features STREQUAL __rho_vcpkg_manifest_features)
      set(discover_default_features 1)
    endif()
  endif()

  set(default_features "")
  if(discover_default_features)
    rho_vcpkg_json(NAME vcpkg_name)
    list(TRANSFORM VCPKG_OVERLAY_PORTS PREPEND "--overlay-ports=" OUTPUT_VARIABLE overlay_ports)
    list(TRANSFORM VCPKG_OVERLAY_TRIPLETS PREPEND "--overlay-triplets=" OUTPUT_VARIABLE overlay_triplets)

    execute_process(
      COMMAND
        "${__rho_vcpkg_exe}" depend-info
        "--overlay-ports=${RHO_CURRENT_MANIFEST_DIR}"
        ${overlay_ports}
        ${overlay_triplets}
        "--max-recurse=0"
        "${vcpkg_name}:${VCPKG_TARGET_TRIPLET}"
      WORKING_DIRECTORY "${RHO_CURRENT_MANIFEST_DIR}"
      OUTPUT_VARIABLE depend_info
      ERROR_VARIABLE depend_info
      RESULT_VARIABLE depend_info_result)

    if(NOT depend_info_result EQUAL "0")
      __rho_block_message(
        "vcpkg depend-info failed:"
        "${depend_info}")
      message(FATAL_ERROR "depend-info failed")
    elseif(depend_info MATCHES "${vcpkg_name}:")
      set(default_features "")
    elseif(depend_info MATCHES "${vcpkg_name}\\[([-,a-z0-9 ]*)\\]:")
      string(REPLACE ", " ";" default_features "${CMAKE_MATCH_1}")
    else()
      __rho_block_message(
        "Unable to parse vcpkg depend-info output:"
        "${depend_info}")
      message(FATAL_ERROR "depend-info output")
    endif()
  endif()

  if(__rho_top_level_project)
    # we can only set this without screwing with our parent if we're the top level
    set(__rho_vcpkg_manifest_features "${vcpkg_manifest_features}" CACHE INTERNAL "")
  endif()

  message(STATUS "vcpkg default-features for this project: ${default_features}")

  # note: only used if __rho_top_level_project
  set(features "")

  foreach(feature IN LISTS vcpkg_manifest_features)
    if(feature STREQUAL "test")
      if(BUILD_TESTING)
        rho_list(APPEND features "${feature}")
      endif()
      continue()
    elseif(feature STREQUAL "dev")
      if(DEVELOPER_MODE)
        rho_list(APPEND features "${feature}")
      endif()
      continue()
    endif()

    string(TOUPPER "${feature}" upper_feat)
    string(REPLACE "-" "_" upper_feat "${upper_feat}")
    if(feature IN_LIST default_features)
      option("FEATURE_${upper_feat}" "Enable the ${feature} feature" "ON")
    else()
      option("FEATURE_${upper_feat}" "Enable the ${feature} feature" "OFF")
    endif()

    if("${FEATURE_${upper_feat}}")
      rho_list(APPEND features "${feature}")
    endif()
  endforeach()

  if(__rho_top_level_project)
    rho_list(PRETTY_PRINT pretty_features features)
    message(STATUS "vcpkg features to install: ${pretty_features}")
    set(VCPKG_MANIFEST_NO_DEFAULT_FEATURES ON CACHE INTERNAL "")
    set(VCPKG_MANIFEST_FEATURES "${features}" CACHE INTERNAL "")
  endif()

endblock()
