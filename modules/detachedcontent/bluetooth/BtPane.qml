pragma ComponentBehavior: Bound

import qs.widgets
import qs.config
import QtQuick
import QtQuick.Layouts

RowLayout {
    anchors.fill: parent

    spacing: 0

    Item {
        Layout.preferredWidth: Math.floor(parent.width / 3)
        Layout.fillHeight: true

        DeviceList {
            anchors.margins: Appearance.padding.large + Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.large
            anchors.rightMargin: Appearance.padding.large + Appearance.padding.normal / 2
        }

        InnerBorder {
            leftThickness: 0
            rightThickness: Appearance.padding.normal / 2
        }
    }

    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true

        Details {
            anchors.margins: Appearance.padding.normal
            anchors.leftMargin: Appearance.padding.normal / 2
        }

        InnerBorder {
            leftThickness: Appearance.padding.normal / 2
        }
    }
}
