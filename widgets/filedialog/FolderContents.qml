pragma ComponentBehavior: Bound

import ".."
import qs.services
import qs.config
import qs.utils
import Quickshell
import Quickshell.Io
import Quickshell.Widgets
import QtQuick
import Qt.labs.folderlistmodel

GridView {
    id: root

    required property var dialog

    cellWidth: Sizes.itemWidth + Appearance.spacing.small
    cellHeight: Sizes.itemWidth + Appearance.spacing.small * 2 + Appearance.padding.normal * 2 + 1

    clip: true
    focus: true
    currentIndex: -1
    Keys.onEscapePressed: root.currentIndex = -1

    model: FolderListModel {
        showDirsFirst: true
        folder: {
            let url = "file://";
            if (root.dialog.cwd[0] === "Home")
                url += `${Paths.strip(Paths.home)}/${root.dialog.cwd.slice(1).join("/")}`;
            else
                url += root.dialog.cwd.join("/");
            return url;
        }
        onFolderChanged: root.currentIndex = -1
    }

    delegate: StyledRect {
        id: item

        required property int index
        required property string fileName
        required property string filePath
        required property url fileUrl
        required property string fileSuffix
        required property bool fileIsDir

        readonly property real nonAnimHeight: icon.implicitHeight + name.anchors.topMargin + name.implicitHeight + Appearance.padding.normal * 2

        implicitWidth: Sizes.itemWidth
        implicitHeight: nonAnimHeight

        radius: Appearance.rounding.normal
        color: root.currentItem === item ? Colours.palette.m3primary : "transparent"
        z: root.currentItem === item || implicitHeight !== nonAnimHeight ? 1 : 0
        clip: true

        StateLayer {
            color: root.currentItem === item ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface

            onDoubleClicked: {
                if (item.fileIsDir)
                    root.dialog.cwd.push(item.fileName);
                else
                    root.dialog.accepted(item.filePath);
            }

            function onClicked(): void {
                root.currentIndex = item.index;
            }
        }

        IconImage {
            id: icon

            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            anchors.topMargin: Appearance.padding.normal

            asynchronous: true
            implicitSize: Sizes.itemWidth - Appearance.padding.normal * 2
            source: Quickshell.iconPath(item.fileIsDir ? "inode-directory" : "application-x-zerosize")
            onStatusChanged: {
                if (status === Image.Error)
                    source = Quickshell.iconPath("error");
            }

            Process {
                running: !item.fileIsDir
                command: ["file", "--mime", "-b", item.filePath]
                stdout: StdioCollector {
                    onStreamFinished: {
                        const mime = text.split(";")[0].replace("/", "-");
                        icon.source = mime.startsWith("image-") ? item.fileUrl : Quickshell.iconPath(mime, "image-missing");
                    }
                }
            }
        }

        StyledText {
            id: name

            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: icon.bottom
            anchors.topMargin: Appearance.spacing.small
            anchors.margins: Appearance.padding.normal

            horizontalAlignment: Text.AlignHCenter
            text: item.fileName
            color: root.currentItem === item ? Colours.palette.m3onPrimary : Colours.palette.m3onSurface
            elide: root.currentItem === item ? Text.ElideNone : Text.ElideRight
            wrapMode: root.currentItem === item ? Text.WrapAtWordBoundaryOrAnywhere : Text.NoWrap
        }

        Behavior on implicitHeight {
            NumberAnimation {
                duration: Appearance.anim.durations.normal
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Appearance.anim.curves.standard
            }
        }
    }
}
