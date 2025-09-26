cmake_minimum_required(VERSION 3.25)

# TODO: this should be rho_add_unit_test
include("${CMAKE_CURRENT_LIST_DIR}/cmake/my_add_unit_test.cmake")

add_subdirectory(library)
add_subdirectory(foo/boo)

add_test(
  NAME cmake-install
  COMMAND ${CMAKE_COMMAND} --install ${CMAKE_BINARY_DIR} --config $<CONFIG>
          --prefix "${CMAKE_CURRENT_BINARY_DIR}/cmake/$<CONFIG>/install/"
)
