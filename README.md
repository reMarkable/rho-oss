# Rho

Rho is the reMarkable CMake library; it is our attempt to make CMake ergonomic.

It works within the CMake framework, avoiding custom concepts. It attempts to
follow the principles laid out in Robert Schumacher's [Don't Package your Libraries][].
It results in a packageable library, without the pain of everything that goes into
writing an installable library in CMake.

[Don't Package Your Libraries]: https://youtu.be/sBP17HQAQjk

This should not be taken as a "fully-complete", productised library. It is a first
attempt at what I hope will result in a conversation about how to move forward with
CMake ergonomics.

## Examples

I have written some examples of libraries which use rho, located on my personal github.
You can see them here:

* [rho-mu][] – a simple library using rho
* [rho-depends][] – a simple library which depends on rho-mu
* [beicode][] – a conversion of an existing Microsoft example library to rho
  - includes an interesting history of how to convert a library
* [beison][] – same as beicode, but one which depends on beicode

[rho-mu]: https://github.com/strega-nil-re/rho-mu
[rho-depends]: https://github.com/strega-nil-re/rho-depends
[beicode]: https://github.com/strega-nil-re/beicode
[beison]: https://github.com/strega-nil-re/beison
