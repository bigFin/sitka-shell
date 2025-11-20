import qs.components
import qs.services
import "../../../config"
import qs.modules.launcher.services
import QtQuick

Item {
    id: root

    required property Actions.Action modelData
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

        Item {
            anchors.left: icon.right
            anchors.leftMargin: Config.appearance.spacing.normal
            anchors.verticalCenter: icon.verticalCenter

            implicitWidth: parent.width - icon.width
            implicitHeight: name.implicitHeight + desc.implicitHeight

            StyledText {
                id: name

                text: root.modelData?.name ?? ""
                font.pointSize: Config.appearance.font.size.normal
            }

            StyledText {
                id: desc

                text: root.modelData?.desc ?? ""
                font.pointSize: Config.appearance.font.size.small
                color: Colours.palette.m3outline

                elide: Text.ElideRight
                width: root.width - icon.width - Config.appearance.rounding.normal * 2

                anchors.top: name.bottom
            }
        }
    }
}
