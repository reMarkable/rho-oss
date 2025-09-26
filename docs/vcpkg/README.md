# rho's portfile support

These are the basics of writing portfiles under rho. Hopefully, the rho library
makes it easy and simple to write portfiles, both in-line and in the registry.

Unlike standard vcpkg ports, where the definition of how to build and install
the port is out-of-line, contained in the registry, rho portfiles are defined
inline to the repository where the sources are. We get this done via two vcpkg
functions: [`rho_vcpkg_from_local`][] and [`rho_vcpkg_include_local_portfile`][].

[`rho_vcpkg_from_local`]: rho_vcpkg_from_local.md
[`rho_vcpkg_include_local_portfile`]: rho_vcpkg_include_local_portfile.md

## From the Registry

The registry part of this is very easy; what it does is download the source,
then simply calls into the source repository's portfile to do the build and
install.

```cmake
vcpkg_from_github(
  OUT_SOURCE_PATH SOURCE_PATH
  ...)
rho_vcpkg_include_local_portfile(SOURCE_PATH)
```

## From the Source Repository

#### To be written
