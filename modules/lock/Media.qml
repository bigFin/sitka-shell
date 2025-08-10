pragma ComponentBehavior: Bound

import qs.components
import qs.services
import qs.config
import Quickshell
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    anchors.left: parent.left
    anchors.right: parent.right
    implicitHeight: layout.implicitHeight

    Image {
        anchors.fill: parent
        source: Players.active?.trackArtUrl ?? null

        asynchronous: true
        fillMode: Image.PreserveAspectCrop
        sourceSize.width: width
        sourceSize.height: height

        layer.enabled: true
        layer.effect: ShaderEffect {
            required property Item source
            readonly property Item maskSource: mask

            fragmentShader: `file://${Quickshell.shellDir}/assets/shaders/opacitymask.frag.qsb`
        }
    }

    Rectangle {
        id: mask

        anchors.fill: parent
        layer.enabled: true
        visible: false

        gradient: Gradient {
            orientation: Gradient.Horizontal

            GradientStop {
                position: 0
                color: Qt.rgba(0, 0, 0, 0.5)
            }
            GradientStop {
                position: 0.4
                color: Qt.rgba(0, 0, 0, 0.2)
            }
            GradientStop {
                position: 0.8
                color: Qt.rgba(0, 0, 0, 0)
            }
        }
    }

    ColumnLayout {
        id: layout

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Appearance.padding.large

        StyledText {
            Layout.topMargin: Appearance.padding.large
            text: qsTr("Now playing")
            color: Colours.palette.m3outline
        }

        StyledText {
            Layout.fillWidth: true
            text: Players.active?.trackArtist ?? qsTr("No media")
            color: Colours.palette.m3primary
            horizontalAlignment: Text.AlignHCenter
            font.pointSize: Appearance.font.size.large
            font.weight: 500
            elide: Text.ElideRight
        }

        StyledText {
            Layout.fillWidth: true
            text: Players.active?.trackTitle ?? qsTr("No media")
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.bottomMargin: Appearance.padding.large
        }
    }
}
