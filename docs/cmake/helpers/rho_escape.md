# `rho_escape`

This function transforms strings for various purposes; it supports a few different operations.
Most of them are for transforming between JSON strings and CMake strings, but it does include
an operation for pretty-printing a CMake string.

## Usage

```cmake
rho_escape(<op> <var> <string>)
```

`rho_escape` writes the result of transforming the string `<string>` to `<var>`.

Supported operations:

- [`rho_escape(JSON)`](#rho_escapejson)
- [`rho_escape(JSON_ARRAY)`](#rho_escapejson_array)
- [`rho_escape(JSON_ARRAY_TO_LIST)`](#rho_escapejson_array_to_list)

### `rho_escape(JSON)`
### `rho_escape(JSON_ARRAY)`
### `rho_escape(JSON_ARRAY_TO_LIST)`

