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

rho_test(FAIL too_many_args
  EXPR [[rho_escape(TO_JSON_STRING a b c)]]
  FATAL_ERROR [[^rho_escape was passed extra arguments: c$]])
rho_test(FAIL unknown_op_escape
  EXPR [[rho_escape(FOO a b)]]
  FATAL_ERROR [[^rho_escape: Unknown operation "FOO"$]])
rho_test(FAIL escape_json_array_to_list_nonarray
  EXPR [===[rho_escape(FROM_JSON_ARRAY a [=[ "a" ]=])]===]
  FATAL_ERROR [[^rho_escape\(FROM_JSON_ARRAY\): argument must be an array]])
rho_test(FAIL escape_json_array_to_list_array_nonstrings
  EXPR [===[rho_escape(FROM_JSON_ARRAY a [=[ [ "a", null ] ]=])]===]
  FATAL_ERROR [[^rho_escape\(FROM_JSON_ARRAY\): argument must be an array of strings \(found NULL\)]])

rho_test(SUCCESS basic_json)
function(basic_json)
  rho_escape(TO_JSON_STRING var "a")
  rho_assert(STREQUAL var [["a"]])

  rho_escape(TO_JSON_STRING var "a b")
  rho_assert(STREQUAL var [["a b"]])

  rho_escape(TO_JSON_STRING var "a\\b\nc\"d\"")
  rho_assert(STREQUAL var [["a\\b\nc\"d\""]])

  rho_escape(TO_JSON_STRING var "a\\\\\\\\")
  rho_assert(STREQUAL var [["a\\\\\\\\"]])
endfunction()

rho_test(SUCCESS basic_json_array)
function(basic_json_array)
  rho_escape(TO_JSON_ARRAY var [[]])
  rho_assert(JSON_EQUAL var "[]")

  rho_escape(TO_JSON_ARRAY var [[a]])
  rho_assert(JSON_EQUAL var [=[["a"]]=])

  rho_escape(TO_JSON_ARRAY var [[a;b]])
  rho_assert(JSON_EQUAL var [=[["a","b"]]=])

  rho_escape(TO_JSON_ARRAY var "\"a\";b\n")
  rho_assert(JSON_EQUAL var [=[["\"a\"","b\n"]]=])

  rho_escape(TO_JSON_ARRAY var "a\\;b")
  rho_assert(JSON_EQUAL var [=[ [ ["a", "b"] ] ]=])

  rho_escape(TO_JSON_ARRAY var "a\\;b;c")
  rho_assert(JSON_EQUAL var [=[[["a","b"],"c"]]=])
endfunction()

rho_test(SUCCESS basic_json_array_to_list)
function(basic_json_array_to_list)
  set(var blah)
  rho_escape(FROM_JSON_ARRAY var [=[[]]=])
  rho_assert(STREQUAL var "")

  rho_escape(FROM_JSON_ARRAY var [=[[ "" ]]=])
  rho_assert(STREQUAL var "")

  rho_escape(FROM_JSON_ARRAY var [=[[ "", "" ]]=])
  rho_assert(STREQUAL var "")

  rho_escape(FROM_JSON_ARRAY var [=[[ "", "a" ]]=])
  rho_assert(STREQUAL var "a")

  rho_escape(FROM_JSON_ARRAY var [=[[ "a", "" ]]=])
  rho_assert(STREQUAL var "a")

  rho_escape(FROM_JSON_ARRAY var [=[[ "a", "", "b" ]]=])
  rho_assert(STREQUAL var "a;b")

  rho_escape(FROM_JSON_ARRAY var [=[[ "a" ]]=])
  rho_assert(STREQUAL var "a")

  rho_escape(FROM_JSON_ARRAY var [=[[ "a", "b" ]]=])
  rho_assert(STREQUAL var "a;b")

  rho_escape(FROM_JSON_ARRAY var [=[[ "\"a", "b\n" ]]=])
  rho_assert(STREQUAL var "\"a;b\n")

  rho_escape(FROM_JSON_ARRAY var [=[[ "a;b" ]]=])
  rho_assert(STREQUAL var "a\\;b")

  rho_escape(FROM_JSON_ARRAY var [=[[ "a;b", "c" ]]=])
  rho_assert(STREQUAL var "a\\;b;c")
endfunction()

rho_test_finalize()
