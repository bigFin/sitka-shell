.pragma library

function invoke(event, callback) {
    if (event && event.isAutoRepeat)
        return false;
    callback();
    return true;
}
