#include <rho/test-package/library/version.hpp>

#include <string>

#include <fmt/format.h>

namespace rho::test_package {

std::string library::version() noexcept
{
    return fmt::format("{}.{}.{}", 0, 0, 1);
}

} // namespace rho::test_package
