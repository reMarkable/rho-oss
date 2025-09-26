# `rho_vcpkg_from_local`

`rho_vcpkg_from_local` is one of two portfile functions that allow you to write
a portfile in-line to the repo, rather than the standard method of writing the
portfile into the registry.

## Usage

```cmake
rho_vcpkg_from_local(<source-path-var>)
```

It's a fairly simple function and does fairly little. If the portfile is called
at the top-level, in an overlay port situation, it sets `<source-path-var>` to
the directory of the portfile.

Otherwise, the portfile is being called from
`rho_vcpkg_include_local_portfile`, in which case it sets `<source-path-var>`
to an internal variable set by that macro.
