#pragma once

#include <rho/test-package/foo/boo/export_macro.h>

#include <string>

namespace rho::test_package::foo::boo {

[[nodiscard]] RHO_TEST_PACKAGE_FOO_BOO_EXPORT std::string version() noexcept;

} // namespace rho::test_package::foo::boo
