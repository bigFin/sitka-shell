import qs.components
import qs.services
import "../../config"
import QtQuick
import QtQuick.Layouts

GridLayout {
    id: root

    required property var lock

    readonly property bool isPortrait: height > width
    columns: isPortrait ? 2 : 3
    flow: GridLayout.LeftToRight

    rowSpacing: Config.appearance.spacing.large * 2
    columnSpacing: Config.appearance.spacing.large * 2

    ColumnLayout {
        Layout.row: root.isPortrait ? 1 : 0
        Layout.column: 0
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignTop
        
        spacing: Config.appearance.spacing.normal

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: weather.implicitHeight

            topLeftRadius: Config.appearance.rounding.large
            radius: Config.appearance.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            WeatherInfo {
                id: weather

                rootHeight: root.height
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            radius: Config.appearance.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            Fetch {}
        }

        StyledClippingRect {
            Layout.fillWidth: true
            implicitHeight: media.implicitHeight

            bottomLeftRadius: Config.appearance.rounding.large
            radius: Config.appearance.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            Media {
                id: media

                lock: root.lock
            }
        }
    }

    Center {
        Layout.row: 0
        Layout.column: root.isPortrait ? 0 : 1
        Layout.columnSpan: root.isPortrait ? 2 : 1
        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
        Layout.fillHeight: !root.isPortrait

        lock: root.lock
    }

    ColumnLayout {
        Layout.row: root.isPortrait ? 1 : 0
        Layout.column: root.isPortrait ? 1 : 2
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.alignment: Qt.AlignTop
        
        spacing: Config.appearance.spacing.normal

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: resources.implicitHeight

            topRightRadius: Config.appearance.rounding.large
            radius: Config.appearance.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            Resources {
                id: resources
            }
        }

        StyledRect {
            Layout.fillWidth: true
            Layout.fillHeight: true

            bottomRightRadius: Config.appearance.rounding.large
            radius: Config.appearance.rounding.small
            color: Colours.tPalette.m3surfaceContainer

            NotifDock {
                lock: root.lock
            }
        }
    }
}
