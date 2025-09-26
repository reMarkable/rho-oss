#include <rho/test-package/foo/boo/version.hpp>

#include <string>

namespace rho::test_package::foo::boo {

std::string version() noexcept
{
    return "0.0.1-foo-boo";
}

} // namespace rho::foo::boo
