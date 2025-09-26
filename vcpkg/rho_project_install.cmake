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

function(rho_project_install)
  rho_parse_arguments(
    OPTION_ARGS
      NO_INSTALL_LICENSE
    SINGLE_ARGS
      SOURCE_PATH
      CONFIG_PATH
      LICENSE
      COPYRIGHT_YEAR COPYRIGHT_HOLDER
      LICENSE_FILE
    REQUIRED_ARGS
      SOURCE_PATH)

  if(arg_NO_INSTALL_LICENSE)
    foreach(nonsense_arg IN ITEMS LICENSE LICENSE_FILE COPYRIGHT_HOLDER COPYRIGHT_YEAR)
      if(DEFINED "arg_${nonsense_arg}")
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: It doesn't make sense to pass both NO_INSTALL_LICENSE and ${nonsense_arg}")
      endif()
    endforeach()
  elseif(DEFINED arg_LICENSE_FILE)
    set(arg_NO_INSTALL_LICENSE 1)

    vcpkg_install_copyright(FILE_LIST "${arg_LICENSE_FILE}")
  endif()

  if(NOT arg_NO_INSTALL_LICENSE)
    if(NOT DEFINED arg_LICENSE)
      rho_vcpkg_json(LICENSE arg_LICENSE
        PATH "${CMAKE_CURRENT_LIST_DIR}/vcpkg.json")
      if(NOT DEFINED arg_LICENSE)
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: No license found in vcpkg.json, and no LICENSE passed; you should pass NO_INSTALL_LICENSE")
      endif()
    endif()

    if(NOT DEFINED arg_COPYRIGHT_HOLDER)
      message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: We must know who the copyright holder is; please pass COPYRIGHT_HOLDER argument")
    endif()
    if(NOT DEFINED arg_COPYRIGHT_YEAR)
      message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: We must know when the copyright is; please pass COPYRIGHT_YEAR argument")
    endif()
  endif()

  rho_vcpkg_json(FEATURES vcpkg_features
    PATH "${CMAKE_CURRENT_LIST_DIR}/vcpkg.json")

  set(cmake_features "")
  foreach(feat IN LISTS vcpkg_features)
    if(feat STREQUAL "test")
      rho_list(APPEND cmake_features test BUILD_TESTING)
    elseif(feat STREQUAL "dev")
      continue()
    else()
      string(TOUPPER "${feat}" upper_feat)
      string(REPLACE "-" "_" upper_feat "${upper_feat}")
      rho_list(APPEND cmake_features "${feat}" "FEATURE_${upper_feat}")
    endif()
  endforeach()

  if(NOT "${cmake_features}" STREQUAL "")
    vcpkg_check_features(
      PREFIX feat
      OUT_FEATURE_OPTIONS feature_opts
      FEATURES
        ${cmake_features})
  else()
    set(feature_opts "")
  endif()

  vcpkg_cmake_configure(
    SOURCE_PATH "${arg_SOURCE_PATH}"
    OPTIONS
      -DDEVELOPER_MODE=OFF
      "-DRHO_DIRECTORY=${_RHO_DIRECTORY}"
      "-D_RHO_IN_VCPKG=ON"
      ${feature_opts})
  vcpkg_cmake_install()

  file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
  file(REMOVE "${CURRENT_PACKAGES_DIR}/debug/share/${PORT}/usage")

  rho_forward_arguments(SINGLE_ARGS CONFIG_PATH)
  vcpkg_cmake_config_fixup(${param_CONFIG_PATH})

  if(EXISTS "${CURRENT_PACKAGES_DIR}/share/__rho_all_tools")
    file(READ "${CURRENT_PACKAGES_DIR}/share/__rho_all_tools" all_tools)
    vcpkg_copy_tools(
      TOOL_NAMES ${all_tools}
      AUTO_CLEAN)
  endif()

  if(NOT arg_NO_INSTALL_LICENSE)
    rho_install_copyright("${arg_LICENSE}"
      COPYRIGHT_HOLDER "${arg_COPYRIGHT_HOLDER}"
      COPYRIGHT_YEAR "${arg_COPYRIGHT_YEAR}")
  endif()
endfunction()
