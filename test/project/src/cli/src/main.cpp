#include <rho/test-package/library/version.hpp>
#include <rho/test-package/foo/boo/version.hpp>

#include <fmt/core.h>

int main()
{
    fmt::print("rho::test-package version: {}\n", rho::test_package::library::version());
    fmt::print("rho::test-package::foo::boo version: {}\n", rho::test_package::foo::boo::version());
    return 0;
}
