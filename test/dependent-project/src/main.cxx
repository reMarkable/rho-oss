#include <rho/test-package/library/version.hpp>
#include <rho/test-package/foo/boo/version.hpp>

#include <string_view>

int main()
{
    // not that important, just make sure we can call version
    return !rho::test_package::library::version().empty() &&
           !rho::test_package::foo::boo::version().empty() &&
           !std::string_view{TEST_PACKAGE_CLI}.empty();
}
