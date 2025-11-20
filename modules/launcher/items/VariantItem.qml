import qs.modules.launcher.services
import qs.components
import qs.services
import "../../../config"
import QtQuick

Item {
    id: root

    required property M3Variants.Variant modelData
    required property var list

    implicitHeight: Config.launcher.sizes.itemHeight

    anchors.left: parent?.left
    anchors.right: parent?.right

    StateLayer {
        radius: Config.appearance.rounding.small

        function onClicked(): void {
            root.modelData?.onClicked(root.list);
        }
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: Config.appearance.padding.larger
        anchors.rightMargin: Config.appearance.padding.larger
        anchors.margins: Config.appearance.padding.smaller

        MaterialIcon {
            id: icon

            text: root.modelData?.icon ?? ""
            font.pointSize: Config.appearance.font.size.extraLarge

            anchors.verticalCenter: parent.verticalCenter
        }

        Column {
            anchors.left: icon.right
            anchors.leftMargin: Config.appearance.spacing.larger
            anchors.verticalCenter: icon.verticalCenter

            width: parent.width - icon.width - anchors.leftMargin - (current.active ? current.width + Config.appearance.spacing.normal : 0)
            spacing: 0

            StyledText {
                text: root.modelData?.name ?? ""
                font.pointSize: Config.appearance.font.size.normal
            }

            StyledText {
                text: root.modelData?.description ?? ""
                font.pointSize: Config.appearance.font.size.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                anchors.left: parent.left
                anchors.right: parent.right
            }
        }

        Loader {
            id: current

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

            active: root.modelData?.variant === Schemes.currentVariant
            asynchronous: true

            sourceComponent: MaterialIcon {
                text: "check"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.size.large
            }
        }
    }
}
