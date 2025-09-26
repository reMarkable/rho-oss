#pragma once

#include <rho/test-package/library/export_macro.h>

#include <string>

namespace rho::test_package::library {

[[nodiscard]] RHO_TEST_PACKAGE_LIBRARY_EXPORT std::string version() noexcept;

} // namespace rho::test_package::library
