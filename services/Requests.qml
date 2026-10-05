pragma Singleton

import Quickshell
import QtQuick
import "../utils/scripts/requestLifecycle.js" as RequestLifecycle

Singleton {
    id: root

    // Existing two-argument callers remain success-only. The returned function
    // cancels once; optional failure receives http:STATUS/network/timeout/cancelled.
    function get(url: string, callback: var, failure: var): var {
        return RequestLifecycle.get(new XMLHttpRequest(), url, callback, reason => {
            if (reason !== "cancelled")
                console.warn(`[REQUESTS] GET request to ${url} failed: ${reason}`);
            if (failure)
                failure(reason);
        }, (expire, interval) => {
            const timer = deadline.createObject(root, { expire: expire, interval: interval });
            timer.start();
            return () => {
                timer.stop();
                timer.destroy();
            };
        }, 15000);
    }

    Component {
        id: deadline
        Timer {
            property var expire
            onTriggered: expire()
        }
    }
}
