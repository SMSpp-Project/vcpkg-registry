# quadprog has no build of its own: its three C sources make a static
# library, whose qpgen2_ the users declare themselves
cmake_minimum_required(VERSION 3.19)
project(quadprog C)

add_library(quadprog STATIC
    quadprog/solve.QP.c quadprog/linear-algebra.c quadprog/qr-update.c)
if (NOT MSVC)
    target_link_libraries(quadprog PRIVATE m)
endif ()

install(TARGETS quadprog ARCHIVE DESTINATION lib)
