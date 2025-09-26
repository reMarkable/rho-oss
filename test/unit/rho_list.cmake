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

rho_test(FAIL invalid_operator
  EXPR [[rho_list(FLOOP lst)]]
  FATAL_ERROR "^rho_list: unknown operation: FLOOP$")

rho_test(FAIL invalid_varname_setting
  EXPR "rho_list(SET {lst})"
  FATAL_ERROR "^rho_list: invalid variable name: {lst}$")
rho_test(FAIL invalid_varname_query_out
  EXPR "rho_list(GET {out} lst 0)"
  FATAL_ERROR "^rho_list: invalid variable name: {out}$")
rho_test(FAIL invalid_varname_query_list
  EXPR "rho_list(GET out {lst} 0)"
  FATAL_ERROR "^rho_list: invalid variable name: {lst}$")
rho_test(FAIL invalid_varname_modifying_list
  EXPR "rho_list(POP_FRONT {lst})"
  FATAL_ERROR "^rho_list: invalid variable name: {lst}$")
rho_test(FAIL invalid_varname_modifying_out
  EXPR "set(lst a)\nrho_list(POP_FRONT lst {out})"
  FATAL_ERROR "^rho_list: invalid variable name: {out}$")
rho_test(FAIL invalid_varname_foreach_range_out
  EXPR "rho_list(FOREACH_RANGE {out} LIST lst)"
  FATAL_ERROR "^rho_list: invalid variable name: {out}$")
rho_test(FAIL invalid_varname_foreach_range_list
  EXPR "rho_list(FOREACH_RANGE out LIST {lst})"
  FATAL_ERROR "^rho_list: invalid variable name: {lst}$")
rho_test(FAIL cache_var_out_query
  EXPR "rho_list(GET CACHE{out} lst 0)"
  FATAL_ERROR [[^rho_list\(GET\): out variable must not be a cache variable: CACHE{out}$]])
rho_test(FAIL cache_var_out_foreach_range
  EXPR "rho_list(FOREACH_RANGE CACHE{out} LIST lst)"
  FATAL_ERROR [[^rho_list\(FOREACH_RANGE\): out variable must not be a cache variable: CACHE{out}$]])

foreach(invalid_varname_for_read ARGV ARGV2 ARGN CMAKE_CURRENT_FUNCTION CMAKE_CURRENT_FUNCTION_LIST_DIR __rho_list_blah)
  rho_test(SUCCESS "invalid_varname_for_read_set_${invalid_varname_for_read}"
    EXPR "rho_list(SET ${invalid_varname_for_read})")
  rho_test(FAIL "invalid_varname_for_read_append_${invalid_varname_for_read}"
    EXPR "rho_list(APPEND ${invalid_varname_for_read})"
    FATAL_ERROR "^rho_list: invalid variable name: ${invalid_varname_for_read};")
  rho_test(SUCCESS "invalid_varname_for_read_cache_append_${invalid_varname_for_read}"
    EXPR "rho_list(APPEND CACHE{${invalid_varname_for_read}})")

  rho_test(FAIL "invalid_varname_for_read_modifying_lst_${invalid_varname_for_read}"
    EXPR "rho_list(POP_FRONT ${invalid_varname_for_read} front)"
    FATAL_ERROR "^rho_list: invalid variable name: ${invalid_varname_for_read};")
  rho_test(SUCCESS "invalid_varname_for_read_cache_modifying_lst_${invalid_varname_for_read}"
    EXPR "set(${invalid_varname_for_read} a CACHE INTERNAL a)\nrho_list(POP_FRONT CACHE{${invalid_varname_for_read}} front)")
  rho_test(SUCCESS "invalid_varname_for_read_modifying_out_${invalid_varname_for_read}"
    EXPR "set(lst a)\nrho_list(POP_FRONT lst ${invalid_varname_for_read})")

  rho_test(SUCCESS "invalid_varname_for_read_query_out_${invalid_varname_for_read}"
    EXPR "rho_list(LENGTH ${invalid_varname_for_read} lst)")
  rho_test(FAIL "invalid_varname_for_read_query_lst_${invalid_varname_for_read}"
    EXPR "rho_list(LENGTH len ${invalid_varname_for_read})"
    FATAL_ERROR "^rho_list: invalid variable name: ${invalid_varname_for_read};")
  rho_test(SUCCESS "invalid_varname_for_read_cache_query_lst_${invalid_varname_for_read}"
    EXPR "rho_list(LENGTH len CACHE{${invalid_varname_for_read}})")

  rho_test(SUCCESS "invalid_varname_for_read_foreach_range_out_${invalid_varname_for_read}"
    EXPR "rho_list(FOREACH_RANGE ${invalid_varname_for_read} LIST lst)")
  rho_test(FAIL "invalid_varname_for_read_foreach_range_lst_${invalid_varname_for_read}"
    EXPR "rho_list(FOREACH_RANGE out LIST ${invalid_varname_for_read})"
    FATAL_ERROR "^rho_list: invalid variable name: ${invalid_varname_for_read};")
  rho_test(SUCCESS "invalid_varname_for_read_cache_foreach_range_lst_${invalid_varname_for_read}"
    EXPR "rho_list(FOREACH_RANGE out LIST CACHE{${invalid_varname_for_read}})")
endforeach()

rho_test(SUCCESS regular_set)
function(regular_set)
  unset(var)
  rho_assert(UNDEFINED var)

  rho_list(SET var)
  rho_assert(STREQUAL var "")

  rho_list(SET var a)
  rho_assert(STREQUAL var "a")

  rho_list(SET var a b)
  rho_assert(STREQUAL var "a;b")

  rho_list(SET var a "b;c")
  rho_assert(STREQUAL var [[a;b\;c]])

  rho_list(SET var a "b;c" [[d\;e\\;f]])
  rho_assert(STREQUAL var [[a;b\;c;d\\;e\\\;f]])

  rho_list(SET var)
  rho_assert(STREQUAL var "")
endfunction()

rho_test(SUCCESS cache_set)
function(cache_set)
  set(var "asdfasdf")
  unset(var CACHE)
  rho_assert(STREQUAL var "asdfasdf")
  rho_assert(UNDEFINED CACHE{var})

  rho_list(SET CACHE{var})
  rho_assert(STREQUAL CACHE{var} "")
  rho_assert(STREQUAL var "asdfasdf")

  rho_list(SET CACHE{var} "")
  rho_assert(STREQUAL CACHE{var} "")
  rho_assert(STREQUAL var "asdfasdf")

  rho_list(SET CACHE{var} a)
  rho_assert(STREQUAL CACHE{var} "a")
  rho_assert(STREQUAL var "asdfasdf")

  rho_list(SET CACHE{var} a b)
  rho_assert(STREQUAL CACHE{var} "a;b")
  rho_assert(STREQUAL var "asdfasdf")

  rho_list(SET CACHE{var} a "b;c")
  rho_assert(STREQUAL CACHE{var} [[a;b\;c]])
  rho_assert(STREQUAL var "asdfasdf")

  rho_list(SET CACHE{var} a "b;c" [[d\;e\\;f]])
  rho_assert(STREQUAL CACHE{var} [[a;b\;c;d\\;e\\\;f]])
  rho_assert(STREQUAL var "asdfasdf")

  rho_list(SET CACHE{var})
  rho_assert(STREQUAL CACHE{var} "")
  rho_assert(STREQUAL var "asdfasdf")
endfunction()

rho_test(SUCCESS normal_append)
function(normal_append)
  unset(var)
  rho_list(APPEND var) # append nothing to undefined
  rho_assert(STREQUAL var "")
  unset(var)
  rho_list(APPEND var "") # append empty string to undefined
  rho_assert(STREQUAL var "")
  unset(var)
  rho_list(APPEND var "" "") # append two empty string to undefined
  rho_assert(STREQUAL var "")

  rho_list(APPEND var) # append nothing to empty string
  rho_assert(STREQUAL var "")
  rho_list(APPEND var "") # append empty string to empty string
  rho_assert(STREQUAL var "")
  rho_list(APPEND var "" "") # append two empty string to empty string
  rho_assert(STREQUAL var "")

  rho_list(APPEND var a) # append something to empty string
  rho_assert(STREQUAL var "a")

  rho_list(APPEND var) # append nothing to something
  rho_assert(STREQUAL var "a")
  rho_list(APPEND var "") # append empty string to something
  rho_assert(STREQUAL var "a")
  rho_list(APPEND var "" "") # append two empty strings to something
  rho_assert(STREQUAL var "a")

  unset(var)
  rho_list(APPEND var a) # append something to undefined
  rho_assert(STREQUAL var "a")

  rho_list(APPEND var b) # append non-list to something
  rho_assert(STREQUAL var "a;b")

  rho_list(APPEND var "c;d") # append list to something
  rho_assert(STREQUAL var [[a;b;c\;d]])

  unset(var)
  rho_list(APPEND var "c;d") # append list to undefined
  rho_assert(STREQUAL var [[c\;d]])
endfunction()

rho_test(SUCCESS cache_append)
function(cache_append)
  set(var "asdfasdf")
  unset(var CACHE)

  rho_list(APPEND CACHE{var}) # append nothing to undefined
  rho_assert(STREQUAL CACHE{var} "")
  rho_assert(STREQUAL var "asdfasdf")

  rho_list(APPEND CACHE{var}) # append nothing to nothing
  rho_assert(STREQUAL CACHE{var} "")
  rho_assert(STREQUAL var "asdfasdf")

  rho_list(APPEND CACHE{var} a) # append something to nothing
  rho_assert(STREQUAL CACHE{var} "a")
  rho_assert(STREQUAL var "asdfasdf")

  unset(var CACHE)
  rho_list(APPEND CACHE{var} a) # append something to undefined
  rho_assert(STREQUAL CACHE{var} "a")
  rho_assert(STREQUAL var "asdfasdf")

  rho_list(APPEND CACHE{var} b) # append non-list to something
  rho_assert(STREQUAL CACHE{var} "a;b")
  rho_assert(STREQUAL var "asdfasdf")

  rho_list(APPEND CACHE{var} "c;d") # append list to something
  rho_assert(STREQUAL CACHE{var} [[a;b;c\;d]])
  rho_assert(STREQUAL var "asdfasdf")

  unset(var CACHE)
  rho_list(APPEND CACHE{var} "c;d") # append list to undefined
  rho_assert(STREQUAL CACHE{var} [[c\;d]])
  rho_assert(STREQUAL var "asdfasdf")
endfunction()

rho_test(FAIL pop_front_unset
  EXPR "unset(lst)\nrho_list(POP_FRONT lst var)"
  FATAL_ERROR [[^rho_list\(POP_FRONT\): attempted to pop off of an empty list$]])
rho_test(FAIL pop_front_empty
  EXPR "set(lst \"\")\nrho_list(POP_FRONT lst var)"
  FATAL_ERROR [[^rho_list\(POP_FRONT\): attempted to pop off of an empty list$]])

rho_test(SUCCESS pop_front_basic)
function(pop_front_basic)
  set(lst "a")
  rho_list(POP_FRONT lst var)
  rho_assert(STREQUAL var "a")
  rho_assert(STREQUAL lst "")

  set(lst "a;b;c")
  rho_list(POP_FRONT lst var)
  rho_assert(STREQUAL var "a")
  rho_assert(STREQUAL lst "b;c")

  set(lst "a;b\\;c")
  rho_list(POP_FRONT lst var)
  rho_assert(STREQUAL var "a")
  rho_assert(STREQUAL lst "b\\;c")
  rho_list(POP_FRONT lst var)
  rho_assert(STREQUAL var "b;c")
  rho_assert(STREQUAL lst "")
endfunction()

rho_test(SUCCESS pop_front_cache)
function(pop_front_cache)
  set(lst "asdfasdf")

  set(lst "a" CACHE INTERNAL "")
  rho_list(POP_FRONT CACHE{lst} var)
  rho_assert(STREQUAL var "a")
  rho_assert(STREQUAL CACHE{lst} "")

  set(lst "a;b;c" CACHE INTERNAL "")
  rho_list(POP_FRONT CACHE{lst} var)
  rho_assert(STREQUAL var "a")
  rho_assert(STREQUAL CACHE{lst} "b;c")

  set(lst "a;b\\;c" CACHE INTERNAL "")
  rho_list(POP_FRONT CACHE{lst} var)
  rho_assert(STREQUAL var "a")
  rho_assert(STREQUAL CACHE{lst} "b\\;c")
  rho_list(POP_FRONT CACHE{lst} var)
  rho_assert(STREQUAL var "b;c")
  rho_assert(STREQUAL CACHE{lst} "")

  rho_assert(STREQUAL lst "asdfasdf")
endfunction()

rho_test(SUCCESS basic_length)
function(basic_length)
  unset(lst)
  rho_list(LENGTH var lst)
  rho_assert(EQUAL var 0)

  set(lst "")
  rho_list(LENGTH var lst)
  rho_assert(EQUAL var 0)

  set(lst "a")
  rho_list(LENGTH var lst)
  rho_assert(EQUAL var 1)

  set(lst "a;b")
  rho_list(LENGTH var lst)
  rho_assert(EQUAL var 2)

  set(lst [[a\;b]])
  rho_list(LENGTH var lst)
  rho_assert(EQUAL var 1)
endfunction()

rho_test(SUCCESS cache_length)
function(cache_length)
  set(lst "a;b;c")

  unset(lst CACHE)
  rho_list(LENGTH var CACHE{lst})
  rho_assert(EQUAL var 0)
  rho_list(LENGTH var lst)
  rho_assert(EQUAL var 3)

  set(lst "" CACHE INTERNAL "")
  rho_list(LENGTH var CACHE{lst})
  rho_assert(EQUAL var 0)
  rho_list(LENGTH var lst)
  rho_assert(EQUAL var 3)

  set(lst "a" CACHE INTERNAL "")
  rho_list(LENGTH var CACHE{lst})
  rho_assert(EQUAL var 1)
  rho_list(LENGTH var lst)
  rho_assert(EQUAL var 3)

  set(lst "a;b" CACHE INTERNAL "")
  rho_list(LENGTH var CACHE{lst})
  rho_assert(EQUAL var 2)

  set(lst [[a\;b]] CACHE INTERNAL "")
  rho_list(LENGTH var CACHE{lst})
  rho_assert(EQUAL var 1)
endfunction()

rho_test(SUCCESS basic_pretty_print)
function(basic_pretty_print)
  unset(lst)
  rho_list(PRETTY_PRINT var lst)
  rho_assert(STREQUAL var "")

  set(lst "")
  rho_list(PRETTY_PRINT var lst)
  rho_assert(STREQUAL var "")

  set(lst ";a")
  rho_list(PRETTY_PRINT var lst)
  rho_assert(STREQUAL var [["" a]])

  set(lst [[""]])
  rho_list(PRETTY_PRINT var lst)
  rho_assert(STREQUAL var [["\"\""]])

  set(lst [[a]])
  rho_list(PRETTY_PRINT var lst)
  rho_assert(STREQUAL var [[a]])

  set(lst [[a\;b]])
  rho_list(PRETTY_PRINT var lst)
  rho_assert(STREQUAL var [["a;b"]])

  set(lst "hello world;goodbye")
  rho_list(PRETTY_PRINT var lst)
  rho_assert(STREQUAL var [["hello world" goodbye]])

  set(lst "hello\nworld\tand\\friends\;now;goodbye")
  rho_list(PRETTY_PRINT var lst)
  rho_assert(STREQUAL var [["hello\nworld\tand\\friends;now" goodbye]])
endfunction()

rho_test(FAIL get_unset
  EXPR "unset(lst)\nrho_list(GET var lst 0)"
  FATAL_ERROR [[^rho_list\(GET\): attempted to index into an empty list$]])
rho_test(FAIL get_empty
  EXPR "set(lst \"\")\nrho_list(GET var lst 0)"
  FATAL_ERROR [[^rho_list\(GET\): attempted to index into an empty list$]])
rho_test(FAIL get_out_of_bounds
  EXPR "set(lst \"a\")\nrho_list(GET var lst 1)"
  FATAL_ERROR [[^rho_list\(GET\): index 1 outside of range \[-1, 0\]$]])
rho_test(FAIL get_out_of_bounds_neg
  EXPR "set(lst \"a\")\nrho_list(GET var lst -2)"
  FATAL_ERROR [[^rho_list\(GET\): index -2 outside of range \[-1, 0\]$]])
rho_test(FAIL get_non_integer
  EXPR "set(lst \"a\")\nrho_list(GET var lst a)"
  FATAL_ERROR [[rho_list\(GET\): invalid index: a]])

rho_test(SUCCESS basic_get)
function(basic_get)
  set(lst "a")
  rho_list(GET var lst 0)
  rho_assert(STREQUAL var "a")
  rho_list(GET var lst -1)
  rho_assert(STREQUAL var "a")

  set(lst "a;b;c")
  rho_list(GET var lst 0)
  rho_assert(STREQUAL var "a")
  rho_list(GET var lst -1)
  rho_assert(STREQUAL var "c")
  rho_list(GET var lst -2)
  rho_assert(STREQUAL var "b")

  set(lst [[a\;b;c\\;d]])
  rho_list(GET var lst 1)
  rho_assert(STREQUAL var [[c\;d]])
  rho_list(GET var lst -2)
  rho_assert(STREQUAL var [[a;b]])
endfunction()

rho_test(FAIL foreach_range_neither_list_nor_length
  EXPR [[rho_list(FOREACH_RANGE out)]]
  FATAL_ERROR [[^rho_list\(FOREACH_RANGE\): requires either LIST or LENGTH to be passed$]])
rho_test(FAIL foreach_range_both_list_and_length
  EXPR [[rho_list(FOREACH_RANGE out LIST lst LENGTH 3)]]
  FATAL_ERROR [[^rho_list\(FOREACH_RANGE\): requires only one of LIST or LENGTH to be passed$]])
rho_test(FAIL foreach_range_length_noninteger
  EXPR [[rho_list(FOREACH_RANGE out LENGTH a)]]
  FATAL_ERROR [[^rho_list\(FOREACH_RANGE\): LENGTH \(a\) must be a non-negative integer$]])
rho_test(FAIL foreach_range_length_negative
  EXPR [[rho_list(FOREACH_RANGE out LENGTH -1)]]
  FATAL_ERROR [[^rho_list\(FOREACH_RANGE\): LENGTH \(-1\) must be a non-negative integer$]])

rho_test(SUCCESS basic_foreach_range)
function(basic_foreach_range)
  set(lst "a;b;c")
  rho_list(FOREACH_RANGE range LIST lst)
  rho_assert(STREQUAL range "RANGE;0;2")
  rho_list(FOREACH_RANGE range LIST lst FIRST 2)
  rho_assert(STREQUAL range "RANGE;2;2")
  rho_list(FOREACH_RANGE range LIST lst FIRST 3)
  rho_assert(STREQUAL range "")

  set(lst "")
  rho_list(FOREACH_RANGE range LIST lst)
  rho_assert(STREQUAL range "")
  rho_list(FOREACH_RANGE range LIST lst FIRST 2)
  rho_assert(STREQUAL range "")

  rho_list(FOREACH_RANGE range LENGTH 3)
  rho_assert(STREQUAL range "RANGE;0;2")
  rho_list(FOREACH_RANGE range LENGTH 3 FIRST 2)
  rho_assert(STREQUAL range "RANGE;2;2")
  rho_list(FOREACH_RANGE range LENGTH 3 FIRST 3)
  rho_assert(STREQUAL range "")

  rho_list(FOREACH_RANGE range LENGTH 0)
  rho_assert(STREQUAL range "")
  rho_list(FOREACH_RANGE range LENGTH 0 FIRST 2)
  rho_assert(STREQUAL range "")

  set(lst a)
  set(lst "a;b;c" CACHE INTERNAL "")
  rho_list(FOREACH_RANGE range LIST CACHE{lst})
  rho_assert(STREQUAL range "RANGE;0;2")
  rho_list(FOREACH_RANGE range LIST CACHE{lst} FIRST 2)
  rho_assert(STREQUAL range "RANGE;2;2")
  rho_list(FOREACH_RANGE range LIST CACHE{lst} FIRST 3)
  rho_assert(STREQUAL range "")

  set(lst "" CACHE INTERNAL "")
  rho_list(FOREACH_RANGE range LIST CACHE{lst})
  rho_assert(STREQUAL range "")
  rho_list(FOREACH_RANGE range LIST CACHE{lst} FIRST 2)
  rho_assert(STREQUAL range "")
endfunction()

rho_test_finalize()
