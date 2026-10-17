# PIQP is a header-only C++ library whose common templates can be compiled
# into a library; it declares no symbol for a DLL and installs no runtime,
# hence the library is always static, and only its C++ interface is built
vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO PREDICT-EPFL/piqp
    REF v${VERSION}
    SHA512 268c8f659201dc2b8b84894549008541d2be7b4db75fdc39ce1baa1f0019c91c1e088a14fb5386fe13e6274efd548987e838677fc70eff1fccbd27b75264011b
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
