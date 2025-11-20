import qs.components
import qs.services
import "../../config"
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property var lock

    spacing: Config.appearance.spacing.large * 2

    ColumnLayout {
        Layout.fillWidth: true
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
        lock: root.lock
    }

    ColumnLayout {
        Layout.fillWidth: true
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
