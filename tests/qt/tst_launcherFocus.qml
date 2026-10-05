import QtQuick
import QtTest
import "drawerState.js" as DrawerState

TestCase {
    id: testCase
    name: "ShippedLauncherSearch"
    when: windowShown
    visible: true
    width: 500
    height: 200
    property var screens: new Map([["A", first], ["B", second]])

    component ScreenState: QtObject {
        property bool launcher: false
        property bool session: false
        property bool dashboard: false
        property string keyboardDrawer: ""
        property bool changingDrawer: false
        readonly property var enabledDrawers: ({launcher: true, session: true, dashboard: true})
        readonly property string keyboardOwner: DrawerState.keyboardOwner(this, enabledDrawers)
        function claim(owner) { DrawerState.claimKeyboard(testCase.screens, owner); }
        function setDrawer(name, open, intent) { DrawerState.setDrawer(this, enabledDrawers, name, open, intent, claim); }
        onLauncherChanged: DrawerState.changed(this, enabledDrawers, "launcher", claim)
    }
    ScreenState { id: first }
    ScreenState { id: second }
    LauncherSearch { id: search; visibilities: first }
    TextInput { id: otherInput; y: 120; width: 200; height: 30 }

    function test_previewClickTypingAndMonitorReclaim() {
        otherInput.forceActiveFocus();
        first.setDrawer("launcher", true, "passive");
        compare(first.keyboardOwner, "");
        verify(otherInput.activeFocus, "hover leaves existing local focus alone");
        mouseClick(search.field, search.field.width / 2, search.field.height / 2);
        compare(first.keyboardOwner, "launcher");
        verify(search.field.activeFocus);
        keyClick(Qt.Key_A);
        compare(search.field.text, "a");
        second.setDrawer("launcher", true, "explicit");
        compare(first.keyboardOwner, "");
        compare(first.launcher, true);
        compare(second.keyboardOwner, "launcher");
        mouseClick(search.field, search.field.width / 2, search.field.height / 2);
        compare(first.keyboardOwner, "launcher");
        compare(second.keyboardOwner, "");
        verify(search.field.activeFocus);
        search.field.cursorPosition = search.field.text.length;
        keyClick(Qt.Key_B);
        compare(search.field.text, "ab");
    }
}
