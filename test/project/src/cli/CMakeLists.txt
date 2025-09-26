rho_add_executable(cli SKIP_AUTO_BASES)
rho_target_sources(cli
  SOURCE_BASE src
  SOURCES
    SKIP src/wasi_*.cpp)

if(WASI)
  rho_target_sources(cli SOURCES src/wasi_*.cpp)
endif()

target_link_libraries(cli
  PRIVATE
    fmt::fmt
    rho::test-package::library
    rho::test-package::foo::boo)
