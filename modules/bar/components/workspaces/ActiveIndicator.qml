pragma ComponentBehavior: Bound
import qs.components
// import qs.components.effects
import qs.services
import qs.config
import QtQuick

StyledRect {
    id: root

    required property list<Workspace> workspaces
    // required property Item mask
    // required property real maskWidth
    // required property real maskHeight
    required property int groupOffset

    readonly property int currentWsIdx: Niri.focusedWorkspaceIndex - groupOffset
    property real leading: getWsY(currentWsIdx)
    property real trailing: getWsY(currentWsIdx)
    property real currentSize: workspaces[currentWsIdx]?.size ?? 0
    property real offset: Math.min(leading, trailing)
    property real size: {
        const s = Math.abs(leading - trailing) + currentSize;
        if (Config.bar.workspaces.activeTrail && lastWs > currentWsIdx)
            return Math.min(getWsY(lastWs) + (workspaces[lastWs]?.size ?? 0) - offset, s);
        return s;
    }

    property int cWs
    property int lastWs

    function getWsY(idx: int): real {
        let y = 0;
        for (let i = 0; i < idx; i++)
            y += workspaces[i]?.size ?? 0;
        return y;
    }

    onCurrentWsIdxChanged: {
        lastWs = cWs;
        cWs = currentWsIdx;
    }

    clip: false
    x: 1
    y: offset + 1 + Appearance.padding.small / 2
    implicitWidth: Config.bar.sizes.innerWidth
    implicitHeight: size - Appearance.padding.small
    radius: Config.bar.workspaces.rounded ? Appearance.rounding.full : 0
    color: Colours.palette.m3primary
    anchors.horizontalCenter: parent.horizontalCenter

    // Colouriser {
    //     source: root.mask
    //     sourceColor: Colours.palette.m3onSurface
    //     colorizationColor: Colours.palette.m3onPrimary

    //     x: 0
    //     y: -parent.offset
    //     implicitWidth: root.maskWidth
    //     implicitHeight: root.maskHeight

    //     anchors.horizontalCenter: parent.horizontalCenter
    // }

    Loader {
        active: Config.bar.workspaces.focusedWindowBlob
        anchors.horizontalCenter: parent.horizontalCenter

        sourceComponent: Rectangle {
            id: activeWindowIndicator
            width: Niri.focusedWindowId ? Config.bar.sizes.innerWidth + Appearance.padding.normal : 0
            height: Niri.focusedWindowId ? Config.bar.sizes.innerWidth + Appearance.padding.normal : 0 // Match window icon height
            color: Colours.palette.m3primary
            radius: Config.bar.workspaces.rounded ? (Niri.focusedWindowId ? Appearance.rounding.large : Appearance.rounding.full) : 0
            y: {
                const currentWs = root.currentWsIdx + root.groupOffset;
                const wsWindows = Niri.windows.filter(w => w.workspace_id === currentWs + 1);
                const focusedWindow = wsWindows.find(w => w.id === root.workspaces[root.currentWsIdx]?.focusedWindowId);

                if (!focusedWindow)
                    return Appearance.spacing.large / 2;

                var focusedIndex = wsWindows.indexOf(focusedWindow);

                if (Config.bar.workspaces.groupIconsByApp) {
                    // For grouped windows, use the first window's index with same app_id
                    const firstWindowWithSameApp = wsWindows.find(w => w.app_id === focusedWindow.app_id);
                    const firstAppIndex = wsWindows.indexOf(firstWindowWithSameApp);

                    // Count grouped windows before the first occurrence
                    let groupedWindowsBeforeCount = 0;
                    const seenAppIds = new Set();

                    for (let i = 0; i < firstAppIndex; i++) {
                        const appId = wsWindows[i].app_id;
                        if (seenAppIds.has(appId)) {
                            groupedWindowsBeforeCount++;
                        } else {
                            seenAppIds.add(appId);
                        }
                    }

                    focusedIndex = firstAppIndex - groupedWindowsBeforeCount;
                }

                return Config.bar.sizes.innerWidth / 1.7 /* inaccurate af */  + (focusedIndex * (Config.bar.workspaces.windowIconSize + Config.bar.workspaces.windowIconGap));
            }

            Behavior on y {
                Anim {}
            }

            Behavior on width {
                Anim {}
            }

            Behavior on height {
                Anim {}
            }

            Behavior on radius {
                Anim {}
            }
        }
    }

    Behavior on leading {
        enabled: Config.bar.workspaces.activeTrail

        Anim {}
    }

    Behavior on trailing {
        enabled: Config.bar.workspaces.activeTrail

        Anim {
            duration: Appearance.anim.durations.normal * 2
        }
    }

    Behavior on currentSize {
        enabled: Config.bar.workspaces.activeTrail

        Anim {}
    }

    Behavior on offset {
        enabled: !Config.bar.workspaces.activeTrail

        Anim {}
    }

    Behavior on size {
        enabled: !Config.bar.workspaces.activeTrail

        Anim {}
    }

    component Anim: NumberAnimation {
        duration: Appearance.anim.durations.normal
        easing.type: Easing.BezierSpline
        easing.bezierCurve: Appearance.anim.curves.emphasized
    }
}
