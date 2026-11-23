import QtQuick
import QtTest

TestCase {
    id: testCase
    name: "BluetoothRename"
    when: windowShown
    visible: true
    width: 480
    height: 120

    QtObject { id: device; property string name }
    QtObject { id: adapter; property string name }
    QtObject {
        id: bt
        property var active: device
        property var currentAdapter: adapter
        property bool editingDeviceName
        property bool editingAdapterName
    }
    QtObject { id: fakeSession; readonly property alias bt: bt }
    Component { id: devicePage; DetailsRename { session: fakeSession; width: testCase.width } }
    Component { id: adapterPage; SettingsRename { session: fakeSession; width: testCase.width } }
    SignalSpy { id: accepted; signalName: "accepted" }

    function init() {
        device.name = "Headphones";
        adapter.name = "Radio";
        bt.editingDeviceName = bt.editingAdapterName = false;
    }

    function test_rename_data() {
        const cases = [];
        for (const kind of ["device", "adapter"])
            for (const action of ["cancel", "enter", "check"])
                cases.push({tag: kind + "-" + action, isDevice: kind === "device", action});
        return cases;
    }

    function test_rename(data) {
        const model = data.isDevice ? device : adapter;
        const original = model.name;
        const page = createTemporaryObject(data.isDevice ? devicePage : adapterPage, testCase);
        verify(page);
        const field = findChild(page, "renameField");
        const edit = findChild(page, "renameEdit");
        const cancel = findChild(page, "renameCancel");
        const editor = edit.parent;
        accepted.target = field;
        accepted.clear();

        compare(editor.label, data.isDevice ? "Device name" : "Rename adapter (currently does not work)");
        compare(edit.filletSize, data.isDevice ? 2 : 4);
        compare(field.text, original);
        verify(field.readOnly);
        mouseClick(edit);
        tryCompare(field, "activeFocus", true);
        compare(bt.editingDeviceName, data.isDevice);
        compare(bt.editingAdapterName, !data.isDevice);
        verify(!field.readOnly);
        keyClick(Qt.Key_A, Qt.ControlModifier);
        keyClick(Qt.Key_X);
        compare(field.text, "x");
        compare(model.name, original);

        if (data.action === "cancel") {
            mouseClick(cancel);
            compare(accepted.count, 0);
            compare(model.name, original);
            compare(field.text, original);
            model.name = "Changed externally";
            tryCompare(field, "text", model.name);
        } else {
            if (data.action === "enter")
                keyClick(Qt.Key_Return);
            else
                mouseClick(edit);
            compare(accepted.count, 1);
            compare(model.name, data.isDevice ? "x" : original);
        }
        verify(!bt.editingDeviceName && !bt.editingAdapterName);
        verify(field.readOnly);
    }
}
