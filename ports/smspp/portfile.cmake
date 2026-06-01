vcpkg_buildpath_length_warning(37)

# get back tar.gz of tag
vcpkg_from_gitlab(
    GITLAB_URL https://gitlab.com
    OUT_SOURCE_PATH SOURCE_PATH
    REPO smspp/smspp-project
    REF  0.5.0
    SHA512   10013a485ce3f5de0cf9dd0ec3abad0d0b916952ec6c7812603fe6717bdf00c68106d7a2393802518f59e6cfdb427a040e75ed340933e8efb910253e0dc8c899
    HEAD_REF develop
)

# NOTE: smspp-project is an umbrella of git submodules (SMS++, Blocks, Solvers,
# tools). The source archive above does NOT contain submodule contents; they
# must be made available at ${SOURCE_PATH} before configuring (e.g. vendored
# into the registry, or fetched with `git submodule update --init --recursive`).

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
    -DBUILD_tests=OFF
)

vcpkg_install_cmake()
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/doc"  "${CURRENT_PACKAGES_DIR}/debug/doc")
file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
