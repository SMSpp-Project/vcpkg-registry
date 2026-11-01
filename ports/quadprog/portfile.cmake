# quadprog has no build of its own and no header: its three C sources are
# compiled by the CMakeLists.txt of the port into a static library, as
# INSTALL.sh of SMS++ does on Linux and macOS, whose users declare qpgen2_
# themselves; it is under the GPL, hence a library linked with it is too
vcpkg_check_linkage(ONLY_STATIC_LIBRARY)

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO quadprog/quadprog
    REF v${VERSION}
    SHA512 8077360c70d3d98784c57c4d0d461efbb0407805b0f8e2c093aff083c8ade5edf2079ebecbf09578d72dd8b8306c445ee3f6101e45e99fb4b79a8b395e165523
    HEAD_REF master
)

file(COPY "${CMAKE_CURRENT_LIST_DIR}/CMakeLists.txt"
     DESTINATION "${SOURCE_PATH}")

vcpkg_cmake_configure(SOURCE_PATH "${SOURCE_PATH}")
vcpkg_cmake_install()

set(VCPKG_POLICY_EMPTY_INCLUDE_FOLDER enabled)
file(INSTALL "${CMAKE_CURRENT_LIST_DIR}/usage"
     DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}")
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
