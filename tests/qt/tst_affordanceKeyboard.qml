import QtQuick
import QtTest
import "doubles"

TestCase {
    id: testCase
    name: "ShippedNavRailKeyboard"
    when: windowShown
    visible: true
    width: 500
    height: 600

    QtObject {
        id: sessionData
        property bool floating: false
        property bool navExpanded: false
        property string active: "bluetooth"
        property int closes: 0
        property var root: ({close: () => sessionData.closes++})
    }

    NavRail {
        id: rail
        screen: null
        session: sessionData
        width: implicitWidth
        height: implicitHeight
    }

    function control(name) {
        return findChild(rail, name);
    }

    function init() {
        sessionData.floating = false;
        sessionData.navExpanded = false;
        sessionData.active = "bluetooth";
        sessionData.closes = 0;
        WindowFactory.calls = 0;
        tryVerify(() => control("float") !== null);
        control("menu").forceActiveFocus();
    }

    function test_nativeTabAndShiftTab() {
        keyClick(Qt.Key_Tab);
        verify(control("float").activeFocus);
        keyClick(Qt.Key_Tab);
        verify(control("bluetooth").activeFocus);
        keyClick(Qt.Key_Tab);
        verify(control("background").activeFocus);
        keyClick(Qt.Key_Backtab, Qt.ShiftModifier);
        verify(control("bluetooth").activeFocus);
        sessionData.floating = true;
        tryVerify(() => control("float") === null);
        control("menu").forceActiveFocus();
        keyClick(Qt.Key_Tab);
        verify(control("bluetooth").activeFocus, "inactive loader is omitted from the native focus chain");
    }

    function test_shippedActivationHandlers() {
        keyClick(Qt.Key_Return);
        compare(sessionData.navExpanded, true);
        keyClick(Qt.Key_Space);
        compare(sessionData.navExpanded, false);
        control("background").forceActiveFocus();
        keyClick(Qt.Key_Return);
        compare(sessionData.active, "background");
        control("float").forceActiveFocus();
        keyClick(Qt.Key_Space);
        compare(sessionData.closes, 1);
        compare(WindowFactory.calls, 1);
        compare(WindowFactory.lastOptions.active, "background");
        control("menu").Accessible.pressAction();
        compare(sessionData.navExpanded, true);
    }
}
