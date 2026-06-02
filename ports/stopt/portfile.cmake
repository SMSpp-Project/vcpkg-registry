vcpkg_buildpath_length_warning(37)

# get back tar.gz of tag
vcpkg_from_gitlab(
    GITLAB_URL https://gitlab.com
    OUT_SOURCE_PATH SOURCE_PATH
    REPO stochastic-control/StOpt
    REF  v6.3
    SHA512   fc3d8187685d0bd3444ba9c55e50c180211b4302bf043285879cacfc5899d13da68e2dc95f73fa2ccde3fdd07ac422dbb3ca446450f0f58e5332802b3baff6ae
    HEAD_REF master
)

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
    -DBUILD_SDDP=OFF
    -DBUILD_DPCUTS=ON
    -DBUILD_PYTHON=ON
    -DBUILD_TEST=OFF
)

vcpkg_install_cmake()
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/doc"  "${CURRENT_PACKAGES_DIR}/debug/doc")
file(INSTALL ${SOURCE_PATH}/LICENCE.txt DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
