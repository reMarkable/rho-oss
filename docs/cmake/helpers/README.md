# Rho's CMake Helpers

CMake, like a lisp, uses functions and macros to implement what in other
languages would be a built-in feature. However, CMake's built-in functions and
macros have some limitations around lists, and lists of lists.

The CMake language has only one real primitive - parameter passing.
Variables have string value, and lists only exist insomuch as parameters are passed.
There are two ways to pass arguments to a function - quoted, and unquoted.
Each parameter may, or may not, have variable references.

If an argument is quoted, then the parameter of the function is initialized
directly with the string of the argument. Lists are not treated differently
here. However, unquoted arguments are more interesting - this is where lists
actually exist in CMake. Parameters of the called function are initialized with
the string of the argument, split by any semicolons in that string.

It may seem that, in this world, lists of lists would not exist. However, CMake
also has an escape mechanism - when a backslash is before a semicolon, that is
not treated as a split point, and the parameter will get initialized with that
string, with one less backslash. As an example, if you have `var` set to
`a;b\;c\\;d`, and you call `foo(${var})`, `foo`'s parameters will be:

```
ARGV0 = "a"
ARGV1 = [[b;c\;d]]
```

The CMake helpers that Rho provides are:

- [`rho_escape`][]: `rho_escape` gives you a few different string transformations,
  including a bunch of JSON transformers.
- [`rho_list`][]: A `list()` replacement. It re-escapes any list parameters
  passed to it, so that when the resulting list is passed to another function,
  the parameters are initialized with a list, rather than multiple parameters
  being initialized.
- [`rho_parse_arguments`][]: A `cmake_parse_arguments` replacement. It doesn't
  do anything interesting beyond `cmake_parse_arguments(PARSE_ARGV)`, but it
  does look prettier to call, and it checks that extra arguments aren't passed,
  and you're able to check for required arguments.
- [`rho_forward_arguments`][]: A useful helper, for when you take a parameter,
  and have to pass it on to other functions.

[`rho_escape`]: rho_escape.md
[`rho_list`]: rho_list.md
[`rho_parse_arguments`]: rho_parse_arguments.md
[`rho_forward_arguments`]: rho_forward_arguments.md
