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

if(NOT __RHO_CMAKE_HELPERS_INCLUDE)
  message(FATAL_ERROR "You have included ${CMAKE_CURRENT_LIST_FILE} by itself. This is not supported.")
endif()

function(rho_vcpkg_json op out)
  rho_parse_arguments(POSITIONAL_ARGS 2
    SINGLE_ARGS PATH)

  if(NOT DEFINED arg_PATH)
    if(DEFINED RHO_CURRENT_MANIFEST_DIR)
      set(arg_PATH "${RHO_CURRENT_MANIFEST_DIR}/vcpkg.json")
      if(NOT EXISTS "${arg_PATH}")
        message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: RHO_CURRENT_MANIFEST_DIR (${RHO_CURRENT_MANIFEST_DIR}) does not contain a vcpkg.json")
      endif()
    else()
      unset("${out}" PARENT_SCOPE)
      return()
    endif()
  endif()

  cmake_path(ABSOLUTE_PATH arg_PATH BASE_DIRECTORY "${CMAKE_CURRENT_LIST_DIR}" NORMALIZE)
  file(READ "${arg_PATH}" vcpkg_json)

  if(op STREQUAL "NAME")
    string(JSON name ERROR_VARIABLE not_found GET "${vcpkg_json}" name)

    if(not_found)
      unset("${out}" PARENT_SCOPE)
    else()
      set("${out}" "${name}" PARENT_SCOPE)
    endif()
  elseif(op STREQUAL "VERSION")
    string(JSON version ERROR_VARIABLE not_found GET "${vcpkg_json}" version)
    if(not_found)
      string(JSON version ERROR_VARIABLE not_found GET "${vcpkg_json}" version-semver)
    endif()
    if(not_found)
      string(JSON version ERROR_VARIABLE not_found GET "${vcpkg_json}" version-string)
    endif()
    if(not_found)
      string(JSON version ERROR_VARIABLE not_found GET "${vcpkg_json}" version-date)
      string(REPLACE "-" "." version "${version}")
    endif()

    if(not_found)
      unset("${out}" PARENT_SCOPE)
    else()
      set("${out}" "${version}" PARENT_SCOPE)
    endif()
  elseif(op STREQUAL "FEATURES")
    string(JSON features_len ERROR_VARIABLE not_found LENGTH "${vcpkg_json}" features)
    if(not_found OR features_len EQUAL 0)
      set("${out}" "" PARENT_SCOPE)
      return()
    endif()

    set(result "")
    math(EXPR last_feature "${features_len} - 1")
    foreach(feature_idx RANGE 0 "${last_feature}")
      string(JSON feat MEMBER "${vcpkg_json}" features "${feature_idx}")
      rho_list(APPEND result "${feat}")
    endforeach()

    set("${out}" "${result}" PARENT_SCOPE)
  elseif(op STREQUAL "LICENSE")
    string(JSON license ERROR_VARIABLE not_found GET "${vcpkg_json}" license)
    if(not_found)
      unset("${out}" PARENT_SCOPE)
    else()
      set("${out}" "${license}" PARENT_SCOPE)
    endif()
  else()
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: Unknown operation ${op}")
  endif()
endfunction()
