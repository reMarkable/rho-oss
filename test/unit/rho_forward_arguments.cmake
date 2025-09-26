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

rho_test(FAIL invalid_arg
  EXPR [[rho_forward_arguments(hi)]]
  FATAL_ERROR [[^rho_forward_arguments was passed extra arguments: hi$]])
rho_test(FAIL invalid_args
  EXPR [[rho_forward_arguments(hi ho)]]
  FATAL_ERROR [[^rho_forward_arguments was passed extra arguments: hi ho$]])
rho_test(FAIL bad_variable_name
  EXPR [[rho_forward_arguments(OPTION_ARGS hi={ho})]]
  FATAL_ERROR [[^rho_forward_arguments: Invalid argument "hi={ho}" passed; expected "VARNAME" or "VARNAME=OTHERVAR"$]])

rho_test(SUCCESS no_args
  EXPR [[rho_forward_arguments()]])
rho_test(SUCCESS only_nil_prefix
  EXPR [[rho_forward_arguments(ARG_PREFIX "")]])
rho_test(SUCCESS only_prefix
  EXPR [[rho_forward_arguments(ARG_PREFIX arg)]])

rho_test(SUCCESS basic)
function(basic)
  set(arg_opt 1)
  set(arg_other 0)
  rho_forward_arguments(OPTION_ARGS opt other)
  rho_assert(STREQUAL param_opt "opt")
  rho_assert(STREQUAL param_other "")

  set(arg_list "foo;bar")
  set(arg_inner_list "foo\;bar")
  set(arg_empty "") # edge case
  unset(undefined)
  rho_forward_arguments(SINGLE_ARGS list inner_list empty undefined)
  rho_assert(STREQUAL param_list [[list;foo\;bar]])
  rho_assert(STREQUAL param_inner_list [[inner_list;foo\\;bar]])
  rho_assert(STREQUAL param_empty "")
  rho_assert(STREQUAL param_undefined "")

  rho_forward_arguments(MULTI_ARGS list inner_list empty undefined)
  rho_assert(STREQUAL param_list [[list;foo;bar]])
  rho_assert(STREQUAL param_inner_list [[inner_list;foo\;bar]])
  rho_assert(STREQUAL param_empty "")
  rho_assert(STREQUAL param_undefined "")

  unset(param_opt)
  rho_forward_arguments(ARG_PREFIX floop OPTION_ARGS opt)
  rho_assert(STREQUAL floop_opt "opt")
  rho_assert(UNDEFINED param_opt)
endfunction()

rho_test(SUCCESS arg_parsing)
function(arg_parsing)
  set(opt 1)
  set(noopt 0)
  set(var "a;b")
  unset(undef)
  rho_forward_arguments(
    OPTION_ARGS
      OPT=opt
      NOOPT=noopt
    SINGLE_ARGS
      SING=var
      USING=undef
    MULTI_ARGS
      MULT=var
      UMULT=undef)
  rho_assert(STREQUAL param_OPT "OPT")
  rho_assert(STREQUAL param_NOOPT "")
  rho_assert(STREQUAL param_SING "SING;a\;b")
  rho_assert(STREQUAL param_USING "")
  rho_assert(STREQUAL param_MULT "MULT;a;b")
  rho_assert(STREQUAL param_UMULT "")
endfunction()

rho_test_finalize()
