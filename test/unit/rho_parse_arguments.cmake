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

include(RhoCMakeTest)
include(RhoCMakeHelpers)

function(set_argv)
  set(ARGC "${ARGC}" PARENT_SCOPE)
  if(NOT ARGC EQUAL "0")
    math(EXPR last_arg "${ARGC} - 1")
    foreach(index RANGE 0 "${last_arg}")
      set("ARGV${index}" "${ARGV${index}}" PARENT_SCOPE)
    endforeach()
  endif()
endfunction()

rho_test(FAIL unparsed_args
  EXPR [[
    set_argv(asdf flasdf "foo;bar")
    rho_parse_arguments()]]
  FATAL_ERROR [[^rho_test_finalize was passed extra arguments: asdf flasdf "foo;bar"$]])
rho_test(FAIL rpa_unparsed_args
  EXPR [[
    set_argv()
    rho_parse_arguments(asdf flasdf "foo;bar")]]
    FATAL_ERROR [[^rho_parse_arguments was passed extra arguments: asdf flasdf foo bar$]])

rho_test(FAIL single_no_args_end
  EXPR [[
    set_argv(FOO)
    rho_parse_arguments(SINGLE_ARGS FOO)]]
  FATAL_ERROR [[^rho_test_finalize: argument keyword FOO was not given a value before the end of the argument list$]])
rho_test(FAIL multi_no_args_end
  EXPR [[
    set_argv(FOO)
    rho_parse_arguments(MULTI_ARGS FOO)]]
  FATAL_ERROR [[^rho_test_finalize: argument keyword FOO was not given a value before the end of the argument list$]])
rho_test(FAIL single_no_args_new_kw
  EXPR [[
    set_argv(FOO BAR)
    rho_parse_arguments(SINGLE_ARGS FOO OPTION_ARGS BAR)]]
  FATAL_ERROR [[^rho_test_finalize: argument keyword FOO was not given a value before switching to new keyword BAR;]])
rho_test(FAIL multi_no_args_new_kw
  EXPR [[
    set_argv(FOO BAR)
    rho_parse_arguments(MULTI_ARGS FOO OPTION_ARGS BAR)]]
  FATAL_ERROR [[^rho_test_finalize: argument keyword FOO was not given a value before switching to new keyword BAR;]])
rho_test(SUCCESS single_empty_arg_end
  EXPR [[
    set_argv(FOO "")
    rho_parse_arguments(SINGLE_ARGS FOO)
    rho_assert(STREQUAL arg_FOO "")]])
rho_test(SUCCESS multi_empty_arg_end
  EXPR [[
    set_argv(FOO "")
    rho_parse_arguments(MULTI_ARGS FOO)
    rho_assert(STREQUAL arg_FOO "")]])
rho_test(SUCCESS single_empty_arg_new_kw
  EXPR [[
    set_argv(FOO "" BAR)
    rho_parse_arguments(SINGLE_ARGS FOO OPTION_ARGS BAR)
    rho_assert(STREQUAL arg_FOO "")]])
rho_test(SUCCESS multi_empty_arg_new_kw
  EXPR [[
    set_argv(FOO "" BAR)
    rho_parse_arguments(MULTI_ARGS FOO OPTION_ARGS BAR)
    rho_assert(STREQUAL arg_FOO "")]])

rho_test(SUCCESS unparsed_args_allowed)
function(unparsed_args_allowed)
  set_argv(asdf blasdf "a;b")
  rho_parse_arguments(ALLOW_UNPARSED_ARGS)
  rho_assert(STREQUAL arg_UNPARSED_ARGS [[asdf;blasdf;a\;b]])

  rho_parse_arguments(ALLOW_UNPARSED_ARGS POSITIONAL_ARGS 1)
  rho_assert(STREQUAL arg_UNPARSED_ARGS [[blasdf;a\;b]])

  unset(arg_UNPARSED_ARGS)
  rho_parse_arguments(ALLOW_UNPARSED_ARGS ARG_PREFIX blarp)
  rho_assert(STREQUAL blarp_UNPARSED_ARGS [[asdf;blasdf;a\;b]])
  rho_assert(UNDEFINED arg_UNPARSED_ARGS)

  set_argv([[a\\\;b]])
  rho_parse_arguments(ALLOW_UNPARSED_ARGS)
  rho_assert(STREQUAL arg_UNPARSED_ARGS [[a\\\\;b]])
endfunction()

rho_test(SUCCESS basic)
function(basic)
  set(arg_UNPARSED_ARGS "something")
  set_argv(SING a MULT b1 b2 OPT)
  rho_parse_arguments(
    OPTION_ARGS OPT UOPT
    SINGLE_ARGS SING USING
    MULTI_ARGS MULT UMULT)
  rho_assert(STREQUAL arg_OPT "1")
  rho_assert(STREQUAL arg_UOPT "0")
  rho_assert(STREQUAL arg_SING "a")
  rho_assert(UNDEFINED arg_USING)
  rho_assert(STREQUAL arg_MULT "b1;b2")
  rho_assert(UNDEFINED arg_UMULT)
  rho_assert(UNDEFINED arg_UNPARSED_ARGS)

  rho_parse_arguments(
    ARG_PREFIX arg2
    ALLOW_UNPARSED_ARGS
    POSITIONAL_ARGS 1
    OPTION_ARGS OPT UOPT
    SINGLE_ARGS SING USING
    MULTI_ARGS MULT UMULT)
  rho_assert(STREQUAL arg2_OPT "1")
  rho_assert(STREQUAL arg2_UOPT "0")
  rho_assert(UNDEFINED arg2_SING)
  rho_assert(UNDEFINED arg2_USING)
  rho_assert(STREQUAL arg2_MULT "b1;b2")
  rho_assert(UNDEFINED arg2_UMULT)
  rho_assert(STREQUAL arg2_UNPARSED_ARGS "a")

  set_argv(SING a b)
  rho_parse_arguments(SINGLE_ARGS SING ALLOW_UNPARSED_ARGS)
  rho_assert(STREQUAL arg_SING "a")
  rho_assert(STREQUAL arg_UNPARSED_ARGS "b")
endfunction()

rho_test(SUCCESS lists)
function(lists)
  set_argv(SING "a;b" MULT a "b;c")
  rho_parse_arguments(
    SINGLE_ARGS SING
    MULTI_ARGS MULT)
  rho_assert(STREQUAL arg_SING "a;b")
  rho_assert(STREQUAL arg_MULT [[a;b\;c]])
endfunction()

rho_test(SUCCESS hash_parsing)
function(hash_parsing)
  set_argv(SINGLE_ARGS)
  rho_parse_arguments(
    OPTION_ARGS "#SINGLE_ARGS")
  rho_assert(UNDEFINED arg_UNPARSED_ARGS)
  rho_assert(STREQUAL arg_SINGLE_ARGS "1")

  set_argv(SINGLE_ARGS "#BLAH")
  rho_parse_arguments(
    OPTION_ARGS "#BLAH"
    MULTI_ARGS "#SINGLE_ARGS")
  rho_assert(STREQUAL arg_SINGLE_ARGS "BLAH")
  rho_assert(STREQUAL arg_BLAH "0")
endfunction()


rho_test_finalize()
