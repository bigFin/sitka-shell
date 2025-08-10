import Quickshell.Wayland
import Quickshell.Services.Pam
import QtQuick

PamContext {
    id: root

    required property WlSessionLock lock

    property string state: "none"
    property string buffer: ""

    function handleKey(event: KeyEvent): void {
        if (active)
            return;

        if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return) {
            start();
        } else if (event.key === Qt.Key_Backspace) {
            if (event.modifiers & Qt.ControlModifier) {
                buffer = "";
            } else {
                buffer = buffer.slice(0, -1);
            }
        } else if (" abcdefghijklmnopqrstuvwxyz1234567890`~!@#$%^&*()-_=+[{]}\\|;:'\",<.>/?".includes(event.text.toLowerCase())) {
            // No illegal characters (you are insane if you use unicode in your password)
            buffer += event.text;
        }
    }

    onResponseRequiredChanged: {
        if (!responseRequired)
            return;

        respond(buffer);
        buffer = "";
    }

    onCompleted: res => {
        if (res === PamResult.Success)
            return lock.unlock();

        if (res === PamResult.Error)
            state = "error";
        else if (res === PamResult.MaxTries)
            state = "max";
        else if (res === PamResult.Failed)
            state = "fail";
    }
}
