# CaDiCaL is built as its own configure script and makefile build it, and
# installs nothing: the static library and the headers of its API are copied
# where vcpkg wants them. -fPIC lets the library be linked into a shared one.
vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO arminbiere/cadical
    REF rel-${VERSION}
    SHA512 aa1838b58cce726776fc73cd9c54b55af2faf4389b97f672a4dcff007e62aed795ebe3f5862fd292b082e47747eb7672e076e1d5f849ff9cf6ab81210ca2b1f4
    HEAD_REF master
)

vcpkg_execute_required_process(
    COMMAND ./configure -fPIC
    WORKING_DIRECTORY "${SOURCE_PATH}"
    LOGNAME configure-${TARGET_TRIPLET}
)

vcpkg_execute_build_process(
    COMMAND make -j${VCPKG_CONCURRENCY}
    WORKING_DIRECTORY "${SOURCE_PATH}/build"
    LOGNAME build-${TARGET_TRIPLET}
)

file(INSTALL "${SOURCE_PATH}/build/libcadical.a"
     DESTINATION "${CURRENT_PACKAGES_DIR}/lib")
if(NOT VCPKG_BUILD_TYPE)
    file(INSTALL "${SOURCE_PATH}/build/libcadical.a"
         DESTINATION "${CURRENT_PACKAGES_DIR}/debug/lib")
endif()

file(INSTALL "${SOURCE_PATH}/src/cadical.hpp" "${SOURCE_PATH}/src/ccadical.h"
     DESTINATION "${CURRENT_PACKAGES_DIR}/include")

vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
