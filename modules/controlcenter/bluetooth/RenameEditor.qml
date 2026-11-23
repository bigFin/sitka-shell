pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import "../../../config"
import QtQuick
import QtQuick.Layouts

RowLayout {
    id: root

    required property string label
    required property string modelName
    required property bool editing
    property alias editFilletSize: editButton.filletSize
    signal editingRequested(bool active)
    signal accepted(string name)

    Layout.fillWidth: true
    spacing: Config.appearance.spacing.small

    Item {
        id: fieldArea

        Layout.fillWidth: true
        Layout.rightMargin: Config.appearance.spacing.small

        implicitHeight: renameLabel.implicitHeight + nameField.implicitHeight

        states: State {
            name: "editing"
            when: root.editing

            AnchorChanges {
                target: nameField
                anchors.top: fieldArea.top
            }
            PropertyChanges {
                fieldArea.implicitHeight: nameField.implicitHeight
                renameLabel.opacity: 0
                nameField.padding: Config.appearance.padding.normal
            }
        }

        transitions: Transition {
            AnchorAnimation {
                duration: Config.appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Config.appearance.anim.curves.standard
            }
            Anim {
                properties: "implicitHeight,opacity,padding"
            }
        }

        StyledText {
            id: renameLabel

            anchors.left: parent.left

            text: root.label
            color: Colours.palette.m3outline
            font.pointSize: Config.appearance.font.size.small
        }

        StyledTextField {
            id: nameField
            objectName: "renameField"

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: renameLabel.bottom
            anchors.leftMargin: root.editing ? 0 : -Config.appearance.padding.normal

            text: root.modelName
            readOnly: !root.editing
            onAccepted: {
                root.editingRequested(false);
                root.accepted(text);
            }

            leftPadding: Config.appearance.padding.normal
            rightPadding: Config.appearance.padding.normal

            background: StyledRect {
                radius: Config.appearance.rounding.small
                border.width: 2
                border.color: Colours.palette.m3primary
                opacity: root.editing ? 1 : 0

                Behavior on border.color {
                    CAnim {}
                }

                Behavior on opacity {
                    Anim {}
                }
            }

            Behavior on anchors.leftMargin {
                Anim {}
            }
        }
    }

    StyledRect {
        objectName: "renameCancel"
        implicitWidth: implicitHeight
        implicitHeight: cancelEditIcon.implicitHeight + Config.appearance.padding.smaller * 2

        radius: Config.appearance.rounding.small
        color: Colours.palette.m3secondaryContainer
        opacity: root.editing ? 1 : 0
        scale: root.editing ? 1 : 0.5

        StateLayer {
            color: Colours.palette.m3onSecondaryContainer
            disabled: !root.editing

            function onClicked(): void {
                root.editingRequested(false);
                nameField.text = Qt.binding(() => root.modelName);
            }
        }

        MaterialIcon {
            id: cancelEditIcon

            anchors.centerIn: parent
            animate: true
            text: "cancel"
            color: Colours.palette.m3onSecondaryContainer
        }

        Behavior on opacity {
            Anim {}
        }

        Behavior on scale {
            Anim {
                duration: Config.appearance.anim.durations.expressiveFastSpatial
                easing.bezierCurve: Config.appearance.anim.curves.expressiveFastSpatial
            }
        }
    }

    StyledRect {
        id: editButton
        objectName: "renameEdit"

        implicitWidth: implicitHeight
        implicitHeight: editIcon.implicitHeight + Config.appearance.padding.smaller * 2

        radius: 0
        color: Qt.alpha(Colours.palette.m3primary, root.editing ? 1 : 0)

        StateLayer {
            color: root.editing ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

            function onClicked(): void {
                if (root.editing) {
                    nameField.accepted();
                } else {
                    root.editingRequested(true);
                    nameField.forceActiveFocus();
                }
            }
        }

        MaterialIcon {
            id: editIcon

            anchors.centerIn: parent
            animate: true
            text: root.editing ? "check_circle" : "edit"
            color: root.editing ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
        }

        Behavior on radius {
            Anim {}
        }
    }
}
