#include <rho/test-package/foo/boo/version.hpp>
#include <catch2/catch_test_macros.hpp>

namespace rho::test_package::foo::boo::tests {

TEST_CASE("version is correct") {
  REQUIRE(rho::test_package::foo::boo::version() == "0.0.1-foo-boo");
}

} // namespace rho::test_package::foo::boo::tests
