pragma ComponentBehavior: Bound

import qs.components
import qs.components.effects
import qs.services
import "../../config"
import qs.utils
import Quickshell.Services.UPower
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    anchors.fill: parent
    anchors.margins: Config.appearance.padding.large * 2
    anchors.topMargin: Config.appearance.padding.large

    spacing: Config.appearance.spacing.small

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: false
        spacing: Config.appearance.spacing.normal

        StyledRect {
            implicitWidth: prompt.implicitWidth + Config.appearance.padding.normal * 2
            implicitHeight: prompt.implicitHeight + Config.appearance.padding.normal * 2

            color: Colours.palette.m3primary
            radius: Config.appearance.rounding.small

            MonoText {
                id: prompt

                anchors.centerIn: parent
                text: ">"
                font.pointSize: root.width > 400 ? Config.appearance.font.size.larger : Config.appearance.font.size.normal
                color: Colours.palette.m3onPrimary
            }
        }

        MonoText {
            Layout.fillWidth: true
            text: "caelestiafetch.sh"
            font.pointSize: root.width > 400 ? Config.appearance.font.size.larger : Config.appearance.font.size.normal
            elide: Text.ElideRight
        }

        WrappedLoader {
            Layout.fillHeight: true
            active: !iconLoader.active

            sourceComponent: OsLogo {}
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.fillHeight: false
        spacing: height * 0.15

        WrappedLoader {
            id: iconLoader

            Layout.fillHeight: true
            active: root.width > 320

            sourceComponent: OsLogo {}
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: Config.appearance.padding.normal
            Layout.bottomMargin: Config.appearance.padding.normal
            Layout.leftMargin: iconLoader.active ? 0 : width * 0.1
            spacing: Config.appearance.spacing.normal

            WrappedLoader {
                Layout.fillWidth: true
                active: !batLoader.active && root.height > 200

                sourceComponent: FetchText {
                    text: `OS  : ${SysInfo.osPrettyName || SysInfo.osName}`
                }
            }

            WrappedLoader {
                Layout.fillWidth: true
                active: root.height > (batLoader.active ? 200 : 110)

                sourceComponent: FetchText {
                    text: `WM  : ${SysInfo.wm}`
                }
            }

            WrappedLoader {
                Layout.fillWidth: true
                active: !batLoader.active || root.height > 110

                sourceComponent: FetchText {
                    text: `USER: ${SysInfo.user}`
                }
            }

            FetchText {
                text: `UP  : ${SysInfo.uptime}`
            }

            WrappedLoader {
                id: batLoader

                Layout.fillWidth: true
                active: UPower.displayDevice.isLaptopBattery

                sourceComponent: FetchText {
                    text: `BATT: ${UPower.onBattery ? "" : "(+) "}${Math.round(UPower.displayDevice.percentage * 100)}%`
                }
            }
        }
    }

    WrappedLoader {
        Layout.alignment: Qt.AlignHCenter
        active: root.height > 180

        sourceComponent: RowLayout {
            spacing: Config.appearance.spacing.large

            Repeater {
                model: Math.max(0, Math.min(8, root.width / (Config.appearance.font.size.larger * 2 + Config.appearance.spacing.large)))

                StyledRect {
                    required property int index

                    implicitWidth: implicitHeight
                    implicitHeight: Config.appearance.font.size.larger * 2
                    color: Colours.palette[`term${index}`]
                    radius: Config.appearance.rounding.small
                }
            }
        }
    }

    component WrappedLoader: Loader {
        asynchronous: true
        visible: active
    }

    component OsLogo: ColouredIcon {
        source: SysInfo.osLogo
        implicitSize: height
        colour: Colours.palette.m3primary
        layer.enabled: Config.lock.recolourLogo || SysInfo.isDefaultLogo
    }

    component FetchText: MonoText {
        Layout.fillWidth: true
        font.pointSize: root.width > 400 ? Config.appearance.font.size.larger : Config.appearance.font.size.normal
        elide: Text.ElideRight
    }

    component MonoText: StyledText {
        font.family: Config.appearance.font.family.mono
    }
}
