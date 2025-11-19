import qs.services
import qs.config
import qs.modules.osd as Osd
import qs.modules.notifications as Notifications
import qs.modules.session as Session
import qs.modules.launcher as Launcher
import qs.modules.dashboard as Dashboard
import qs.modules.bar.popouts as BarPopouts
import qs.modules.utilities as Utilities
import QtQuick

Item {
    id: root

    required property Panels panels
    required property Item bar

    anchors.fill: parent
    anchors.margins: Config.border.thickness
    anchors.leftMargin: bar.implicitWidth

    Osd.Background {
        wrapper: root.panels.osd
        x: root.width - root.panels.session.width
        y: (root.height - wrapper.height) / 2
        width: wrapper.width
        height: wrapper.height
    }

    Notifications.Background {
        wrapper: root.panels.notifications
        x: root.width
        y: 0
        width: wrapper.width
        height: wrapper.height
    }

    Session.Background {
        wrapper: root.panels.session
        x: root.width
        y: (root.height - wrapper.height) / 2
        width: wrapper.width
        height: wrapper.height
    }

    Launcher.Background {
        wrapper: root.panels.launcher
        x: (root.width - wrapper.width) / 2
        y: root.height
        width: wrapper.width
        height: wrapper.height
    }

    Dashboard.Background {
        wrapper: root.panels.dashboard
        x: (root.width - wrapper.width) / 2
        y: 0
        width: wrapper.width
        height: wrapper.height
    }

    BarPopouts.Background {
        wrapper: root.panels.popouts
        invertBottomRounding: wrapper.y + wrapper.height + 1 >= root.height
        x: wrapper.x
        y: wrapper.y
        width: wrapper.width
        height: wrapper.height
    }

    Utilities.Background {
        wrapper: root.panels.utilities
        x: root.width
        y: root.height
        width: wrapper.width
        height: wrapper.height
    }
}