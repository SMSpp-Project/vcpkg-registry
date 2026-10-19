# qpmad is a header-only C++ library: only its headers and its CMake
# configuration are installed
set(VCPKG_BUILD_TYPE release)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO asherikov/qpmad
    REF ${VERSION}
    SHA512 63abad3ab264120e01280554f8fc67ceef6d81417ce2c8841a4b95638f45a9fe4fcefd09919ca7e55f13c213c66ced9e85e0d13803e0e8d958ce0b7cceb54717
    HEAD_REF master
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DQPMAD_BUILD_TESTS=OFF
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH share/qpmad/cmake)

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
