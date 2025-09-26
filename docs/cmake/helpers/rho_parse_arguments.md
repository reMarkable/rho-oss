# `rho_parse_arguments`

Parse the arguments to a function, correctly handling errors and the like.

## Usage

```cmake
rho_parse_arguments(
  [ALLOW_UNPARSED_ARGS]
  [POSITIONAL_ARGS <N>]
  [ARG_PREFIX <prefix>]
  [OPTION_ARGS <kw>...]
  [SINGLE_ARGS <kw>...]
  [MULTI_ARGS <kw>...]
  [REQUIRED_ARGS <kw>...])
```

You may notice that the parameter keywords are a little ugly - this is so that
user's keywords are unlikely to clash, since CMake works in such a way that
makes it really difficult to distinguish parameters to macros.

### Parameters

#### `ALLOW_UNPARSED_ARGS`

Allow unparsed arguments to pass by without an error; this will result in the
`<prefix>_UNPARSED_ARGUMENTS` variable containing all arguments we didn't
parse.

#### `POSITIONAL_ARGS <N>`

The first argument to be parsed is the `<N>`-th one. Used for functions with
positional arguments.

#### `ARG_PREFIX <prefix>`

Use the prefix `<prefix>` for arguments instead of the default, `arg`.

#### `OPTION_ARGS <kw>...`

Set the options for your function; these are switches, and are either false
when they are not passed, or true when they are.

#### `SINGLE_ARGS <kw>...`

Sets the single argument keywords for your function. These will be undefined if
not passed, and defined as the single argument otherwise.

#### `MULTI_ARGS <kw>...`

Sets the multi-argument keywords for your function. These will be undefined if
not passed, and defined as a list of all the arguments otherwise.

#### `REQUIRED_ARGS <kw>...`

All of the required keyword arguments to your function.

### Examples

```cmake
function(hi name)
  rho_parse_arguments(POSITIONAL 1 OPTIONS GOODBYE)
  if(arg_GOODBYE)
    message(STATUS "Bye ${name}")
  else()
    message(STATUS "Hello ${name}")
  endif()
endfunction()
hi(Nicole) # Hello Nicole
hi(Nicole GOODBYE) # Bye Nicole
```

```cmake
function(give target)
  rho_parse_arguments(POSITIONAL 1
    OPTIONS "KINDLY"
    SINGLE_ARGS "COST;ITEM"
    REQUIRED "ITEM")

  set(msg "I")
  if(arg_KINDLY)
    set(msg "${msg} kindly")
  endif()
  set(msg "${msg} give ${target} a ${arg_ITEM}")
  if(DEFINED arg_COST)
    set(msg "${msg} for ${arg_COST}")
  endif()
  message(STATUS "${msg}")
endfunction()

give(link KINDLY ITEM sword) # I kindly give link a sword
give(zelda ITEM triforce COST "her soul") # I give zelda a triforce for her soul
give(link) # ERROR: ITEM not passed
give(link blah) # ERROR: extra argument blah
```
