# `rho_vcpkg_include_local_portfile`

`rho_vcpkg_include_local_portfile` is one of two portfile functions that allow
you to write a portfile in-line to the repo, rather than the standard method of
writing the portfile into the registry.

## Usage

```cmake
rho_vcpkg_include_local_portfile(<source-path-var>)
```

This is a fairly simple macro; it simply sets an internal variable to
`${<source-path-var>}`, and then includes the portfile inside that directory.
