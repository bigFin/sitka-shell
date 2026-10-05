.pragma library

// Qt's XMLHttpRequest has no native timeout. schedule returns a disposer for
// a QML Timer; all terminal paths detach handlers before aborting the transport.
function get(xhr, url, success, failure, schedule, timeoutMs) {
    let settled = false;
    let stopTimer = null;
    function finish(reason, text) {
        if (settled)
            return;
        settled = true;
        xhr.onreadystatechange = null;
        xhr.onerror = null;
        if (stopTimer)
            stopTimer();
        xhr.abort();
        if (!reason)
            success(text);
        else if (failure)
            failure(reason);
    }
    try {
        xhr.open("GET", url, true);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === 4)
                finish(xhr.status === 200 ? null : "http:" + xhr.status, xhr.responseText);
        };
        // Harmless on Qt versions without onerror; DONE/status and Timer suffice.
        xhr.onerror = function() { finish("network"); };
        stopTimer = schedule(function() { finish("timeout"); }, timeoutMs);
        xhr.send();
    } catch (e) {
        if (settled)
            throw e;
        finish("exception");
    }
    return function() { finish("cancelled"); };
}
