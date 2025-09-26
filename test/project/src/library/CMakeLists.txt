rho_add_library(library
  INCLUDE_BASE include
  SOURCE_BASE src
  INTERNAL_TARGET_NAME rho-lib)

target_link_libraries(rho-lib
  PRIVATE fmt::fmt)
