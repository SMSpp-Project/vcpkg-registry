vcpkg_buildpath_length_warning(37)

# smspp-project is an umbrella of git submodules (core SMS++, Blocks, Solvers,
# tools). The release source archive does not contain submodule contents, so
# the sources are obtained with a recursive git clone pinned to the release tag
# (0.5.0 == commit f068cc8716e9013e3c0e8f6822359902ea0084a9) instead of
# vcpkg_from_gitlab. All submodule URLs are public https://gitlab.com/smspp/*.
vcpkg_find_acquire_program(GIT)

set(SOURCE_PATH "${CURRENT_BUILDTREES_DIR}/src/smspp-0.5.0")
if(NOT EXISTS "${SOURCE_PATH}/.git")
    file(REMOVE_RECURSE "${SOURCE_PATH}")
    vcpkg_execute_required_process(
        COMMAND "${GIT}" clone --branch 0.5.0 --depth 1
                --recurse-submodules --shallow-submodules
                https://gitlab.com/smspp/smspp-project.git "${SOURCE_PATH}"
        WORKING_DIRECTORY "${CURRENT_BUILDTREES_DIR}"
        LOGNAME clone-${TARGET_TRIPLET}
    )
endif()

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
