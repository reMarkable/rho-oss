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

set(RHO_CXX_STANDARD default
  CACHE STRING "The default C++ standard to compile against")
set(RHO_CXX_INTERFACE_STANDARD default
  CACHE STRING "The C++ standard to require of your dependencies")
set(RHO_CXX_BUILD_STANDARD default
  CACHE STRING "The C++ standard to require to build")

set_property(
  CACHE RHO_CXX_STANDARD RHO_CXX_INTERFACE_STANDARD RHO_CXX_BUILD_STANDARD
  PROPERTY STRINGS "default;11;14;17;20;23;26")

set(RHO_DISABLED_GNU_WARNING_FLAGS "${RHO_DISABLED_GNU_WARNING_FLAGS}"
  CACHE STRING "Any warnings to disable for GCC and clang in GCC mode. Of the form \"shadow;non-virtual-dtor\"")
set(RHO_DISABLED_MSVC_WARNING_FLAGS "${RHO_DISABLED_MSVC_WARNING_FLAGS}"
  CACHE STRING "Any warnings to disable for MSVC and clang in MSVC mode. Of the form \"4251;4275\"")
set(RHO_ENABLED_GNU_WARNING_FLAGS "${RHO_ENABLED_GNU_WARNING_FLAGS}"
  CACHE STRING "Any extra warnings to enable for GCC and clang in GCC mode. Of the form \"shadow;non-virtual-dtor\"")
set(RHO_ENABLED_MSVC_WARNING_FLAGS "${RHO_ENABLED_MSVC_WARNING_FLAGS}"
  CACHE STRING "Any extra warnings to enable for MSVC and clang in MSVC mode. Of the form \"4251;4275\"")

function(__rho_add_gnu_warning_flag target flag)
  if(flag IN_LIST RHO_DISABLED_GNU_WARNING_FLAGS)
    target_compile_options("${target}" PRIVATE "-Wno-${flag}")
  else()
    target_compile_options("${target}" PRIVATE "-W${flag}")
  endif()
endfunction()
function(__rho_add_msvc_warning_flag target flag)
  if(NOT flag IN_LIST RHO_DISABLED_MSVC_WARNING_FLAGS)
    target_compile_options("${target}" PRIVATE "-wd${flag}")
  else()
    target_compile_options("${target}" PRIVATE "-w4${flag}")
  endif()
endfunction()

set(__rho_default_enabled_msvc_warning_flags
  4062 # enumerator 'identifier' in switch of enum 'enumeration' is not handled
  4242 # 'identifier': conversion from 'type1' to 'type2', possible loss of data
  4263 # 'function': member function does not override any base class virtual member function
  4265 # 'class': class has virtual functions, but destructor is not virtual
  4266 # 'function': no override available for virtual member function from base 'type'; function is hidden
  4287 # 'operator': unsigned/negative constant mismatch
  4296 # 'operator': expression is always false
  4545 # expression before comma evaluates to a function which is missing an argument list
  4546 # function call before comma missing argument list
  4547 # 'operator': operator before comma has no effect; expected operator with side-effect
  4549 # 'operator1': operator before comma has no effect; did you intend 'operator2'?
  4555 # expression has no effect; expected expression with side-effect
  4619 # #pragma warning: there is no warning number 'number'
)
set(__rho_default_disabled_msvc_warning_flags
  # disable the following on-by-default warnings which don't make sense for our code
  4251 # 'type': 'type1' needs to have dll-interface to be used by clients of 'type2'
  4275 # non-DLL-interface class 'class_1' used as base for DLL-interface class 'class_2'
  # disable the following on-by-default warning that gives false positives
  4702 # unreachable code
)

set(__rho_default_enabled_gnu_warning_flags
  shadow            # Warn when a local variable or type declaration shadows another variable, parameter, type, or class member.
  non-virtual-dtor  # Warn when a class has virtual functions but no virtual dtor
  old-style-cast    # Warn for c-style casts. Unfortunately does not warn for T(x), which is also a c-style cast.
  cast-qual         # Warn when a pointer is cast so as to remove a type qualifier
  conversion        # Warn for implicit conversions that may alter a value
  sign-conversion   # Warn for implicit conversions that may change the sign of an integer value.
  format-nonliteral # Warn if the format string is not a string literal
)
set(__rho_default_disabled_gnu_warning_flags
  # Disabled, as any alignments that would cause the required alignment to increase are already marked by reinterpret_cast
  cast-align       # Warn when a pointer is cast such that the required alignment of the target is increased.
  # Disabled, as this check has been buggy with libscene
  null-dereference # Warn if the compiler detects paths that trigger UB due to deref a null pointer.
)

macro(__rho_get_enabled_disabled_flags_for_target_flags lowname upname)
  set(enabled_flags "${__rho_default_enabled_${lowname}_warning_flags}")
  set(disabled_flags "${__rho_default_disabled_${lowname}_warning_flags}")

  list(APPEND enabled_flags ${RHO_ENABLED_${upname}_WARNING_FLAGS})
  list(REMOVE_ITEM disabled_flags ${RHO_ENABLED_${upname}_WARNING_FLAGS})
  list(REMOVE_ITEM enabled_flags ${RHO_DISABLED_${upname}_WARNING_FLAGS})
  list(APPEND disabled_flags ${RHO_DISABLED_${upname}_WARNING_FLAGS})

  list(APPEND enabled_flags ${arg_ENABLED_${upname}_WARNING_FLAGS})
  list(REMOVE_ITEM disabled_flags ${arg_ENABLED_${upname}_WARNING_FLAGS})
  list(REMOVE_ITEM enabled_flags ${arg_DISABLED_${upname}_WARNING_FLAGS})
  list(APPEND disabled_flags ${arg_DISABLED_${upname}_WARNING_FLAGS})
endmacro()
function(rho_target_common_flags target)
  rho_parse_arguments(POSITIONAL_ARGS 1
    MULTI_ARGS
      ENABLED_MSVC_WARNING_FLAGS
      ENABLED_GNU_WARNING_FLAGS
      DISABLED_MSVC_WARNING_FLAGS
      DISABLED_GNU_WARNING_FLAGS)

  if(NOT TARGET "${target}")
    message(FATAL_ERROR "${CMAKE_CURRENT_FUNCTION}: passed a target (${target}) which is not built by this project")
  endif()

  get_target_property(target_type "${target}" TYPE)

  set(cxx_standard "${RHO_CXX_STANDARD}")
  if(cxx_standard STREQUAL "default")
    set(cxx_standard 20)
  endif()
  set(cxx_ifc_standard "${RHO_CXX_INTERFACE_STANDARD}")
  if(cxx_ifc_standard STREQUAL "default")
    set(cxx_ifc_standard "${cxx_standard}")
  endif()
  set(cxx_build_standard "${RHO_CXX_BUILD_STANDARD}")
  if(cxx_build_standard STREQUAL "default")
    set(cxx_build_standard "${cxx_standard}")
  endif()

  target_compile_features("${target}" INTERFACE "cxx_std_${cxx_ifc_standard}")
  if(NOT target_type STREQUAL "INTERFACE_LIBRARY")
    target_compile_features("${target}" PRIVATE "cxx_std_${cxx_build_standard}")
  endif()

  set_target_properties("${target}"
    PROPERTIES
      CXX_STANDARD_REQUIRED ON
      CXX_EXTENSIONS OFF
      CXX_VISIBILITY_PRESET hidden
      VISIBILITY_INLINES_HIDDEN ON)

  if(target_type STREQUAL "INTERFACE_LIBRARY")
    return()
  endif()

  if(CMAKE_CXX_COMPILER_ID STREQUAL "GNU")
    target_compile_options("${target}" PRIVATE
      -Wno-psabi # note: parameter passing for argument of type 'type' when std is enabled changed to match previous-std in GCC version
    )
  elseif(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC")
    target_compile_definitions("${target}" PRIVATE
      "-D_CRT_SECURE_NO_WARNINGS" # warning C4996: '%s': This function or variable may be unsafe. (it almost never is)
    )
  endif()

  # these are based on mp-units list of warnings
  # note that some warnings are not enabled since they don't make sense with -permissive-
  if(DEVELOPER_WARNINGS)
    # TODO: this double-check is unnecessary after CMake 3.26 (currently 3.25)
    if(CMAKE_CXX_COMPILER_ID STREQUAL "MSVC" OR CMAKE_CXX_COMPILER_FRONTEND_VARIANT STREQUAL "MSVC")
      target_compile_options("${target}" PRIVATE /W4) # baseline reasonable warnings
      __rho_get_enabled_disabled_flags_for_target_flags(msvc MSVC)
      list(TRANSFORM enabled_flags PREPEND "/w4")
      list(TRANSFORM disabled_flags PREPEND "/wd")
    else()
      target_compile_options("${target}" PRIVATE
        -Wall      # compiling without -Wall is wild
        -Wextra    # baseline reasonable warnings
        -Wpedantic # warn for non-standard C++
      )
      __rho_get_enabled_disabled_flags_for_target_flags(gnu GNU)
      list(TRANSFORM enabled_flags PREPEND "-W")
      list(TRANSFORM disabled_flags PREPEND "-Wno-")
    endif()
    target_compile_options("${target}" PRIVATE ${enabled_flags} ${disabled_flags})
  endif()
endfunction()
