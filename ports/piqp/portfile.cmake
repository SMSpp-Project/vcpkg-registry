# PIQP is a header-only C++ library whose common templates can be compiled
# into a library; it declares no symbol for a DLL and installs no runtime,
# hence the library is always static, and only its C++ interface is built
vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO PREDICT-EPFL/piqp
    REF v${VERSION}
    SHA512 c8cbe9a49c1f4ae99322f4285d09cb84157a51fa877df6eefc34beb1a1685e18f04ff2aed5d62bd10526307615a2e9ffa53f8d1ad4a2e319532167b9e2edd73e
    HEAD_REF main
)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_WITH_TEMPLATE_INSTANTIATION=ON
        -DBUILD_C_INTERFACE=OFF
        -DBUILD_PYTHON_INTERFACE=OFF
        -DBUILD_MATLAB_INTERFACE=OFF
        -DBUILD_OCTAVE_INTERFACE=OFF
        -DBUILD_TESTS=OFF
        -DBUILD_EXAMPLES=OFF
        -DBUILD_BENCHMARKS=OFF
        -DENABLE_INSTALL=ON
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH lib/cmake/piqp)

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
