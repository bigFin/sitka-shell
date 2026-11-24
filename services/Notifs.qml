pragma Singleton
pragma ComponentBehavior: Bound

import qs.config
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import QtQuick
import Sitka

Singleton {
    id: root

    readonly property list<Notif> list: []
    readonly property list<Notif> popups: list.filter(n => n.popup)
    readonly property bool dnd: backend.builtIn ? localDnd : backend.doNotDisturb
    readonly property bool dndAvailable: backend.builtIn || backend.hokumAvailable
    property bool localDnd: false

    function setDnd(enabled: bool): void {
        if (backend.builtIn)
            localDnd = enabled;
        else
            backend.setDoNotDisturb(enabled);
    }

    NotificationBackend { id: backend }

    LazyLoader {
        active: backend.builtIn
        component: NotificationServer {
            keepOnReload: false
            actionsSupported: true
            bodyHyperlinksSupported: true
            bodyImagesSupported: true
            bodyMarkupSupported: true
            imageSupported: true

            onNotification: notif => {
                notif.tracked = true;

                root.list.push(notifComp.createObject(root, {
                    // Keep the arrival-time decision so muted notifications never replay.
                    popup: !root.dnd,
                    notification: notif
                }));
            }
        }
    }

    IpcHandler {
        target: "notifs"

        function clear(): void {
            if (!backend.builtIn) {
                backend.dismissAll();
                return;
            }
            for (const notif of root.list)
                notif.popup = false;
        }
    }

    component Notif: QtObject {
        id: notif

        property bool popup
        readonly property date time: new Date()
        readonly property string timeStr: {
            const diff = Time.date.getTime() - time.getTime();
            const m = Math.floor(diff / 60000);
            const h = Math.floor(m / 60);

            if (h < 1 && m < 1)
                return "now";
            if (h < 1)
                return `${m}m`;
            return `${h}h`;
        }

        required property Notification notification
        readonly property string summary: notification.summary
        readonly property string body: notification.body
        readonly property string appIcon: notification.appIcon
        readonly property string appName: notification.appName
        readonly property string image: notification.image
        readonly property int urgency: notification.urgency
        readonly property list<NotificationAction> actions: notification.actions

        readonly property Timer timer: Timer {
            running: true
            interval: notif.notification.expireTimeout > 0 ? notif.notification.expireTimeout : Config.notifs.defaultExpireTimeout
            onTriggered: {
                if (Config.notifs.expire)
                    notif.popup = false;
            }
        }

        readonly property Connections conn: Connections {
            target: notif.notification.Retainable

            function onDropped(): void {
                root.list.splice(root.list.indexOf(notif), 1);
            }

            function onAboutToDestroy(): void {
                notif.destroy();
            }
        }
    }

    Component {
        id: notifComp

        Notif {}
    }
}
