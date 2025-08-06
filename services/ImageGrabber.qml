pragma Singleton

import Quickshell
import QtQuick

Singleton {
    function grab(target: Item, path: url): void {
        imageGrab.grab(target, path);
    }

    ItemImageGrab {
        id: imageGrab
    }
}
