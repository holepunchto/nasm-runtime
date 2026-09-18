cmake_minimum_required(VERSION 4.0)

find_package(cmake-bare REQUIRED PATHS node_modules/cmake-bare)
find_package(cmake-ports REQUIRED PATHS node_modules/cmake-ports)

project(nasm_runtime C)

bare_target(target)

find_port(nasm)

add_custom_target(nasm_runtime ALL)

add_dependencies(nasm_runtime nasm ndisasm)

install(
  PROGRAMS
    "${nasm_PREFIX}/bin/nasm${CMAKE_EXECUTABLE_SUFFIX}"
    "${nasm_PREFIX}/bin/ndisasm${CMAKE_EXECUTABLE_SUFFIX}"
  DESTINATION ${target}/bin
)
