find_package(PkgConfig REQUIRED)
pkg_check_modules(Qalculate IMPORTED_TARGET libqalculate REQUIRED)
pkg_check_modules(Pipewire IMPORTED_TARGET libpipewire-0.3 REQUIRED)
pkg_check_modules(Aubio IMPORTED_TARGET aubio REQUIRED)

find_path(Cava_INCLUDE_DIR NAMES cava/cavacore.h REQUIRED)
find_library(Cava_LIBRARY NAMES cava REQUIRED)
add_library(Cava::Cava UNKNOWN IMPORTED)
set_target_properties(Cava::Cava PROPERTIES
    IMPORTED_LOCATION "${Cava_LIBRARY}"
    INTERFACE_INCLUDE_DIRECTORIES "${Cava_INCLUDE_DIR}"
)

qt_add_qml_module(sitka
    URI Sitka
    VERSION ${VERSION_SHORT}
    SOURCES
        cutils.hpp cutils.cpp
        cachingimagemanager.hpp cachingimagemanager.cpp
        filesystemmodel.hpp filesystemmodel.cpp
        qalculator.hpp qalculator.cpp
        beattracker.hpp beattracker.cpp
        service.hpp service.cpp
        serviceref.hpp serviceref.cpp
        audiocollector.hpp audiocollector.cpp
        audioprovider.hpp audioprovider.cpp
        cavaprovider.hpp cavaprovider.cpp
        desktopdatabase.hpp desktopdatabase.cpp
)

qt_query_qml_module(sitka
    URI module_uri
    VERSION module_version
    PLUGIN_TARGET module_plugin_target
    TARGET_PATH module_target_path
    QMLDIR module_qmldir
    TYPEINFO module_typeinfo
)

message(STATUS "Created QML module ${module_uri}, version ${module_version}")

set(module_dir "${INSTALL_QMLDIR}/${module_target_path}")
install(TARGETS sitka LIBRARY DESTINATION "${module_dir}" RUNTIME DESTINATION "${module_dir}")
install(TARGETS "${module_plugin_target}" LIBRARY DESTINATION "${module_dir}" RUNTIME DESTINATION "${module_dir}")
install(FILES "${module_qmldir}" DESTINATION "${module_dir}")
install(FILES "${module_typeinfo}" DESTINATION "${module_dir}")

target_link_libraries(sitka PRIVATE
    Qt::Core Qt::Qml Qt::Gui Qt::Concurrent Qt::Multimedia
    PkgConfig::Qalculate PkgConfig::Pipewire PkgConfig::Aubio Cava::Cava
)
