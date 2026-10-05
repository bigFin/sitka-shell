.pragma library

// One explicit input owner per screen. Passive reveals never replace that owner.
var focusDrawers = ["launcher", "session", "dashboard"];

function setDrawer(state, enabled, drawer, open, intent, acquire) {
    if (focusDrawers.indexOf(drawer) < 0)
        return;
    if (open && !enabled[drawer])
        return;
    if (intent === "passive" && state.keyboardDrawer)
        return;
    if (open && intent !== "passive" && acquire)
        acquire(state);
    state.changingDrawer = true;
    if (open && intent !== "passive") {
        for (var i = 0; i < focusDrawers.length; ++i) {
            var other = focusDrawers[i];
            if (other !== drawer)
                state[other] = false;
        }
        state.keyboardDrawer = drawer;
    } else if (!open && state.keyboardDrawer === drawer) {
        state.keyboardDrawer = "";
    }
    state[drawer] = open;
    state.changingDrawer = false;
}

// Legacy pointer-click callers assign booleans directly; these are explicit.
function changed(state, enabled, drawer, acquire) {
    if (!state.changingDrawer) {
        if (state[drawer] && !enabled[drawer]) {
            setDrawer(state, enabled, drawer, false, "explicit");
            return;
        }
        setDrawer(state, enabled, drawer, state[drawer], "explicit", acquire);
    }
}

function keyboardOwner(state, enabled) {
    var drawer = state.keyboardDrawer;
    return enabled[drawer] && state[drawer] ? drawer : "";
}

function unregister(map, key, value) {
    if (map.get(key) === value)
        map.delete(key);
}

function unregisterValue(map, value) {
    map.forEach(function(current, key) {
        if (current === value)
            map.delete(key);
    });
}

function activeScreen(screens, name) {
    return screens.get(name) || screens.values().next().value || null;
}

// Visibility remains screen-local; only exclusive keyboard intent is global.
function claimKeyboard(screens, owner) {
    screens.forEach(function(state) {
        if (state !== owner)
            state.keyboardDrawer = "";
    });
}
