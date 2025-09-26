#include <rho/test-package/library/version.hpp>
#include <catch2/catch_test_macros.hpp>

TEST_CASE("version is correct") {
  REQUIRE(rho::test_package::library::version() == "0.0.1");
}
