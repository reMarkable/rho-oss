# `rho_list`

A function replacing CMake's `list()` function. This correctly handles internal semicolons in arguments, and also supports a CACHE option.

## Usage

- Modifers:
  - [`rho_list(SET <list-name> [args...])`](#rho_listset)
  - [`rho_list(APPEND <list-name> [args...])`](#rho_listappend)
- Query operators:
  - [`rho_list(LENGTH <out-var> <list-name>)`](#rho_listlength)
  - [`rho_list(GET <out-var> <list-name> <index>)`](#rho_listget)
  - [`rho_list(PRETTY_PRINT <out-var> <list-name>)`](#rho_listpretty_print)
- Other helpers:
  - [`rho_list(FOREACH_RANGE <out-var> [FIRST <index>] (LIST <list-name> | LENGTH <length>))`](#rho_listforeach_range)

For each of these, `<list-name>` may be `CACHE{name}`, in which case `rho_list` reads from and writes to the cache.

### `rho_list(SET)`
### `rho_list(APPEND)`

### `rho_list(LENGTH)`
### `rho_list(GET)`
### `rho_list(PRETTY_PRINT)`

### `rho_list(FOREACH_RANGE)`

