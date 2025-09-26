# `rho_forward_args`

This function helps users call functions with optional arguments.

## Usage

```cmake
rho_forward_args(
  [ARG_PREFIX <prefix>]
  [OPTION_ARGS <ARGNAME>[=<var>]...]
  [SINGLE_ARGS <ARGNAME>[=<var>]...]
  [MULTI_ARGS <ARGNAME>[=<var>]...])
```

By default, if `=<var>` is not passed for a specific argument, it is taken to
be `arg_<ARGNAME>`. By default, `<prefix>` is taken to be `"param"`.

For OPTION args, if `<var>` is defined and set to a truthy value,
`<prefix>_<ARGNAME>` will be set to `"<ARGNAME>"`; else, `<prefix>_<ARGNAME>`
will be an empty list, so that passing `${<prefix>_<ARGNAME>}` to a child
function will either pass `<ARGNAME>` or nothing.

Similarly, for SINGLE argument and MULTI arguments, except that the value of
the variable is also in the list. Finally, the only differentiator between
SINGLE and MULTI is whether a list of arguments in the value are to be treated
as one argument, or multiple.

Due to how CMake works, where empty list elements are not passed on to
functions, an empty list in SINGLE and MULTI arguments is treated the same as
not defined, so that one doesn't get errors when one tries to parse arguments.

## Examples

```cmake
rho_parse_arguments(
  OPTION_ARGS
    INTERFACE
  SINGLE_ARGS
    BASE_DIR
  MULTI_ARGS
    PRIVATE_SOURCES)

rho_forward_args(OPTION_ARGS INTERFACE)
add_library(tgt ${param_INTERFACE})

rho_forward_args(
  SINGLE_ARGS BASE_DIR
  MULTI_ARGS PRIVATE=arg_PRIVATE_SOURCES)
target_sources(tgt ${param_BASE_DIR} ${param_PRIVATE})
```
