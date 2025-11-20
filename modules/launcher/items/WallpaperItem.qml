import qs.components
import qs.components.effects
import qs.components.images
import qs.services
import "../../../config"
import Sitka
import Quickshell
import Quickshell.Widgets
import QtQuick

Item {
    id: root

    required property FileSystemEntry modelData
    required property PersistentProperties visibilities

    scale: 0.5
    opacity: 0
    z: PathView.z ?? 0

    Component.onCompleted: {
        scale = Qt.binding(() => PathView.isCurrentItem ? 1 : PathView.onPath ? 0.8 : 0);
        opacity = Qt.binding(() => PathView.onPath ? 1 : 0);
    }

    implicitWidth: image.width + Config.appearance.padding.larger * 2
    implicitHeight: image.height + label.height + Config.appearance.spacing.small / 2 + Config.appearance.padding.large + Config.appearance.padding.normal

    StateLayer {
        radius: Config.appearance.rounding.normal

        function onClicked(): void {
            Wallpapers.setWallpaper(root.modelData.path);
            root.visibilities.launcher = false;
        }
    }

    Elevation {
        anchors.fill: image
        radius: image.radius
        opacity: root.PathView.isCurrentItem ? 1 : 0
        level: 4

        Behavior on opacity {
            Anim {}
        }
    }

    StyledClippingRect {
        id: image

        anchors.horizontalCenter: parent.horizontalCenter
        y: Config.appearance.padding.large
        color: Colours.tPalette.m3surfaceContainer
        radius: Config.appearance.rounding.normal

        implicitWidth: Config.launcher.sizes.wallpaperWidth
        implicitHeight: implicitWidth / 16 * 9

        MaterialIcon {
            anchors.centerIn: parent
            text: "image"
            color: Colours.tPalette.m3outline
            font.pointSize: Config.appearance.font.size.extraLarge * 2
            font.weight: 600
        }

        CachingImage {
            path: root.modelData.path
            smooth: !root.PathView.view.moving

            anchors.fill: parent
        }
    }

    StyledText {
        id: label

        anchors.top: image.bottom
        anchors.topMargin: Config.appearance.spacing.small / 2
        anchors.horizontalCenter: parent.horizontalCenter

        width: image.width - Config.appearance.padding.normal * 2
        horizontalAlignment: Text.AlignHCenter
        elide: Text.ElideRight
        renderType: Text.QtRendering
        text: root.modelData.relativePath
        font.pointSize: Config.appearance.font.size.normal
    }

    Behavior on scale {
        Anim {}
    }

    Behavior on opacity {
        Anim {}
    }
}
