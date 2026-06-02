vcpkg_buildpath_length_warning(37)

# SMS++ and its modules install their CMake package configs under
# lib/cmake/<module> (not share/<port>) and ship .pc/CMake files with absolute
# paths. These are upstream layout choices; accept them for this port.
set(VCPKG_POLICY_SKIP_MISPLACED_CMAKE_FILES_CHECK enabled)
set(VCPKG_POLICY_SKIP_LIB_CMAKE_MERGE_CHECK enabled)
set(VCPKG_POLICY_SKIP_ABSOLUTE_PATHS_CHECK enabled)

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

# SMS++ assumes that, when a netCDFCxx CMake config package is found, it provides
# the target netCDF::netCDFCxx. The vcpkg (and modern upstream) netcdf-cxx4 config
# instead exports netCDF::netcdf-cxx4, so SMS++ links a nonexistent target, and a
# static netcdf-c does not propagate its private deps. This is a packaging concern
# specific to the vcpkg static build, so it is bridged here (in both the build
# tree and the installed package config) rather than upstream in SMS++.
set(netcdf_bridge [[
# vcpkg/modern netcdf-cxx4 exports the target netCDF::netcdf-cxx4, while SMS++
# links netCDF::netCDFCxx, so bridge the names when only the former exists.
# netcdf-c is a static library whose private deps (curl, tinyxml2) reach an
# executable only as deep $<LINK_ONLY:...> entries of netCDF::netcdf; those
# imported targets are frequently not even created in this scope, and when they
# are they are directory-scoped, so executables in sibling subdirectories (e.g.
# UCBlock/tools) silently drop them and fail to link. Find curl/tinyxml2
# explicitly, re-expose them as direct interface deps of netcdf-cxx4 (like
# hdf5), and promote the chain to global so it resolves across the umbrella.
if (TARGET netCDF::netcdf-cxx4 AND NOT TARGET netCDF::netCDFCxx)
    find_package(CURL CONFIG QUIET)
    find_package(tinyxml2 CONFIG QUIET)
    set(_smspp_nc_deps "")
    if (TARGET CURL::libcurl_static)
        list(APPEND _smspp_nc_deps CURL::libcurl_static)
    elseif (TARGET CURL::libcurl)
        list(APPEND _smspp_nc_deps CURL::libcurl)
    endif ()
    if (TARGET tinyxml2::tinyxml2)
        list(APPEND _smspp_nc_deps tinyxml2::tinyxml2)
    endif ()
    foreach (_smspp_nc_tgt netCDF::netcdf-cxx4 netCDF::netcdf ${_smspp_nc_deps}
                           hdf5::hdf5-static hdf5::hdf5_hl-static)
        if (TARGET ${_smspp_nc_tgt})
            get_target_property(_smspp_nc_alias ${_smspp_nc_tgt} ALIASED_TARGET)
            if (NOT _smspp_nc_alias)  # cannot promote an ALIAS; its real target suffices
                set_target_properties(${_smspp_nc_tgt} PROPERTIES IMPORTED_GLOBAL TRUE)
            endif ()
        endif ()
    endforeach ()
    foreach (_smspp_nc_dep ${_smspp_nc_deps})
        set_property(TARGET netCDF::netcdf-cxx4 APPEND
                     PROPERTY INTERFACE_LINK_LIBRARIES ${_smspp_nc_dep})
    endforeach ()
    add_library(netCDF::netCDFCxx ALIAS netCDF::netcdf-cxx4)
endif ()
]])
foreach(_f "${SOURCE_PATH}/SMS++/CMakeLists.txt"
           "${SOURCE_PATH}/SMS++/cmake/SMS++Config.cmake.in")
    vcpkg_replace_string("${_f}"
"if (NOT netCDFCxx_FOUND)
    find_package(netCDFCxx REQUIRED)
endif ()"
"if (NOT netCDFCxx_FOUND)
    find_package(netCDFCxx REQUIRED)
endif ()
${netcdf_bridge}")
endforeach()

vcpkg_configure_cmake(
    SOURCE_PATH ${SOURCE_PATH}
    PREFER_NINJA
    OPTIONS
    -DBUILD_tests=OFF
    -DBUILD_TESTING=OFF
    # netcdf-c is a static lib here, so its private deps (curl, tinyxml2) must
    # propagate as $<LINK_ONLY:...> targets into executables built in sibling
    # subdirectories (e.g. UCBlock/tools). Those imported targets are only
    # directory-scoped by default and get dropped; make all find_package
    # imported targets global so they resolve everywhere in the umbrella.
    -DCMAKE_FIND_PACKAGE_TARGETS_GLOBAL=ON
)

vcpkg_install_cmake()
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/doc"  "${CURRENT_PACKAGES_DIR}/debug/doc")

# LEMON is supplied by the liblemon dependency, but the umbrella's bundled
# LEMONSolver fetches and installs its own copy, which collides with liblemon.
# Drop the duplicated LEMON files (headers, static lib, pkgconfig, CMake config)
# from this package; liblemon still provides them.
file(REMOVE_RECURSE
    "${CURRENT_PACKAGES_DIR}/include/lemon"
    "${CURRENT_PACKAGES_DIR}/share/lemon"
    "${CURRENT_PACKAGES_DIR}/debug/share")
file(REMOVE
    "${CURRENT_PACKAGES_DIR}/lib/libemon.a"
    "${CURRENT_PACKAGES_DIR}/debug/lib/libemon.a"
    "${CURRENT_PACKAGES_DIR}/lib/pkgconfig/lemon.pc"
    "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig/lemon.pc")

# Headers are shipped once (release tree); the debug CMake package configs carry
# per-config include paths into the now-removed debug/include, which breaks
# find_package for consumers. Drop the debug configs so the release config (valid
# for both Debug and Release consumers) is the one that gets used.
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/lib/cmake")

# Tidy up directories left empty by the removals above.
foreach(_d "${CURRENT_PACKAGES_DIR}/lib/pkgconfig"
           "${CURRENT_PACKAGES_DIR}/debug/lib/pkgconfig")
    if(EXISTS "${_d}")
        file(GLOB _d_contents "${_d}/*")
        if(NOT _d_contents)
            file(REMOVE_RECURSE "${_d}")
        endif()
    endif()
endforeach()

file(INSTALL ${SOURCE_PATH}/LICENSE DESTINATION ${CURRENT_PACKAGES_DIR}/share/${PORT} RENAME copyright)
