vcpkg_buildpath_length_warning(37)

# SMS++ and its modules install their CMake package configs under
# lib/cmake/<module> (not share/<port>) and ship .pc/CMake files with absolute
# paths. These are upstream layout choices; accept them for this port.
set(VCPKG_POLICY_SKIP_MISPLACED_CMAKE_FILES_CHECK enabled)
set(VCPKG_POLICY_SKIP_LIB_CMAKE_MERGE_CHECK enabled)
set(VCPKG_POLICY_SKIP_ABSOLUTE_PATHS_CHECK enabled)

# smspp-project is an umbrella of git submodules (core SMS++, Blocks, Solvers,
# tools), so the sources are the tarball of the release, which carries them
# all together with the version of each; the release pipeline puts it in the
# generic package registry of smspp-project.
vcpkg_download_distfile(ARCHIVE
    URLS "https://gitlab.com/api/v4/projects/smspp%2Fsmspp-project/packages/generic/smspp-project/${VERSION}/smspp-project-${VERSION}.tar.gz"
    FILENAME "smspp-project-${VERSION}.tar.gz"
    SHA512 00666bae8680cf266bf3f46d7fb4f440a3401f91e08e34359579d119cc9cc062f1dbb32eac981fb075ce7788412c3d28d148dd47be6b70c226df0f516b195a4e)
vcpkg_extract_source_archive(SOURCE_PATH
    ARCHIVE "${ARCHIVE}"
    NO_REMOVE_ONE_LEVEL)

# the settings of the umbrella for its developers, e.g. shared libraries, give
# way to the ones of vcpkg
file(REMOVE "${SOURCE_PATH}/CMakeSettings.txt")

# feature -> module, whose BUILD_<module> option builds it
set(smspp_modules
    bds BendersDecompositionSolver
    bkb BinaryKnapsackBlock
    bnx BranchAndXSolver
    bundle BundleSolver
    cflb CapacitatedFacilityLocationBlock
    frankwolfe FrankWolfeSolver
    investment InvestmentBlock
    lds LagrangianDualSolver
    lukfi LukFiBlock
    mcf MCFBlock
    mcfclass MCFClassSolver
    mcflemon MCFLemonSolver
    milp MILPSolver
    mmcf MMCFBlock
    mssb MultiStageStochasticBlock
    srs ScenarioReductionSolver
    sddp SDDPBlock
    sfdcr SingleFlowDCRBlock
    stochastic StochasticBlock
    svm SVMBlock
    tools tools
    tssb TwoStageStochasticBlock
    ucblock UCBlock)

set(smspp_feature_pairs "")
set(smspp_umbrella OFF)
set(_smspp_i 0)
list(LENGTH smspp_modules _smspp_n)
while(_smspp_i LESS _smspp_n)
    list(GET smspp_modules ${_smspp_i} _smspp_feature)
    math(EXPR _smspp_i "${_smspp_i} + 1")
    list(GET smspp_modules ${_smspp_i} _smspp_dir)
    math(EXPR _smspp_i "${_smspp_i} + 1")
    list(APPEND smspp_feature_pairs ${_smspp_feature} BUILD_${_smspp_dir})
    if(_smspp_feature IN_LIST FEATURES)
        set(smspp_umbrella ON)
    endif()
endwhile()

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

# SMS++ fetches FastFlow at configure time; the port provides it instead, at a
# fixed commit, so that the build needs no network and is reproducible
vcpkg_from_github(
    OUT_SOURCE_PATH FASTFLOW_SOURCE_PATH
    REPO fastflow/fastflow
    REF d476f66ab924d8d122f54b4b90aee00ef979aea8
    SHA512 15b9a0a365308f063cf15ca111ba5f60af0263692745762593d02597bfb0e5ba1e711c70a5d496c6676c20d9ce28aabec494975f961feb6b5171d131a0e4a3e4
    HEAD_REF master)

vcpkg_check_features(OUT_FEATURE_OPTIONS FEATURE_OPTIONS
    FEATURES ${smspp_feature_pairs})

# The umbrella builds the enabled modules and the core they need; the core
# alone is built from its own directory
if(smspp_umbrella)
    set(smspp_source "${SOURCE_PATH}")
else()
    set(smspp_source "${SOURCE_PATH}/SMS++")
    set(FEATURE_OPTIONS "")
endif()

vcpkg_configure_cmake(
    SOURCE_PATH ${smspp_source}
    PREFER_NINJA
    OPTIONS
    ${FEATURE_OPTIONS}
    -DBUILD_tests=OFF
    -DBUILD_TESTING=OFF
    -DSMSPP_TOOLS_INSTALL_DIR=tools/${PORT}
    -DFETCHCONTENT_SOURCE_DIR_FASTFLOW=${FASTFLOW_SOURCE_PATH}
    # only the dependencies of the port, and not the solvers that the default
    # paths of the umbrella (extlib/) may find elsewhere on the machine
    -DCMAKE_DISABLE_FIND_PACKAGE_CPLEX=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_GUROBI=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_SCIP=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_PIPS=ON
    -DCMAKE_DISABLE_FIND_PACKAGE_Torch=ON
    -DHiGHS_ROOT=${CURRENT_INSTALLED_DIR}
    -DStOpt_ROOT=${CURRENT_INSTALLED_DIR}
    -DCoinUtils_ROOT=${CURRENT_INSTALLED_DIR}
    -DOsi_ROOT=${CURRENT_INSTALLED_DIR}
    -DClp_ROOT=${CURRENT_INSTALLED_DIR}
    # netcdf-c is a static lib here, so its private deps (curl, tinyxml2) must
    # propagate as $<LINK_ONLY:...> targets into executables built in sibling
    # subdirectories (e.g. UCBlock/tools). Those imported targets are only
    # directory-scoped by default and get dropped; make all find_package
    # imported targets global so they resolve everywhere in the umbrella.
    -DCMAKE_FIND_PACKAGE_TARGETS_GLOBAL=ON
)

vcpkg_install_cmake()

# The tools of the tools/ submodule are installed in tools/smspp by the build,
# where they find their configuration; the executables of the modules (e.g.
# nc4generator of UCBlock) are moved there from bin/.
file(GLOB _smspp_bin_exes
     "${CURRENT_PACKAGES_DIR}/bin/*${VCPKG_TARGET_EXECUTABLE_SUFFIX}")
set(_smspp_exe_names "")
foreach(_smspp_exe IN LISTS _smspp_bin_exes)
    if(NOT IS_DIRECTORY "${_smspp_exe}" AND NOT _smspp_exe MATCHES "\\.(dll|pdb)$")
        get_filename_component(_smspp_name "${_smspp_exe}" NAME_WE)
        list(APPEND _smspp_exe_names ${_smspp_name})
    endif()
endforeach()
if(_smspp_exe_names)
    vcpkg_copy_tools(TOOL_NAMES ${_smspp_exe_names} AUTO_CLEAN)
endif()
if(VCPKG_TARGET_IS_WINDOWS AND EXISTS "${CURRENT_PACKAGES_DIR}/tools/${PORT}")
    vcpkg_copy_tool_dependencies("${CURRENT_PACKAGES_DIR}/tools/${PORT}")
endif()
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/tools")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/doc"  "${CURRENT_PACKAGES_DIR}/debug/doc")

# LEMON is supplied by the liblemon dependency, but the umbrella's bundled
# MCFLemonSolver fetches and installs its own copy, which collides with liblemon.
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
