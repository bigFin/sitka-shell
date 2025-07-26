import QtQuick

QtObject {
    readonly property list<string> panes: ["network", "bluetooth"]

    property string active
    property int activeIndex

    onActiveChanged: activeIndex = panes.indexOf(active)
    onActiveIndexChanged: active = panes[activeIndex]
}
