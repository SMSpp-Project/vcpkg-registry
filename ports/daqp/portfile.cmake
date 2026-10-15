# DAQP builds a shared and a static library together, the static one linking
# the shared one, and installs its CMake configuration in <prefix>/cmake: the
# patch lets the build make the one library of the linkage, named daqp in
# both cases, links the math library, exports every symbol of the DLL, which
# declares none, and keeps the GCC flags away from MSVC
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO darnstrom/daqp
    REF v${VERSION}
    SHA512 cb998f325de76bbb3bd53d86cec1e7966531d455e5268c5359c09e150076f5a0d3b66d44dca93aac27b1fce47060a0bb1423a23ab0477e14ab4941bff9ac6884
    HEAD_REF master
    PATCHES
        build-options.patch
)

string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "dynamic" DAQP_SHARED)
string(COMPARE EQUAL "${VCPKG_LIBRARY_LINKAGE}" "static" DAQP_STATIC)

vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DDAQP_BUILD_SHARED=${DAQP_SHARED}
        -DDAQP_BUILD_STATIC=${DAQP_STATIC}
)

vcpkg_cmake_install()
vcpkg_cmake_config_fixup(CONFIG_PATH cmake)
vcpkg_copy_pdbs()

file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")

file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
