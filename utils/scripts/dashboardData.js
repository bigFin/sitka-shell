.pragma library

function initial() {
    return { available: false, loading: false, stale: false, lastUpdate: null };
}

function transition(state, outcome, now) {
    return {
        available: state.available || outcome === "success",
        loading: outcome === "loading",
        stale: outcome === "success" ? false : state.available && (state.stale || outcome === "failure" || outcome === "paused"),
        lastUpdate: outcome === "success" ? now : state.lastUpdate
    };
}

function temperature(value, fahrenheit) {
    if (value == null || String(value).trim() === "" || !Number.isFinite(Number(value)))
        return "—";
    return Number(value) + (fahrenheit ? "°F" : "°C");
}

function utc(date, twelveHour) {
    const hours = date.getUTCHours();
    const minutes = String(date.getUTCMinutes()).padStart(2, "0");
    return String(twelveHour ? (hours % 12 || 12) : hours).padStart(2, "0") + ":" + minutes
        + (twelveHour ? (hours < 12 ? " AM" : " PM") : "") + " UTC";
}

function percent(value, state) {
    return state.available ? Math.round(value * 100) + "%" + (state.stale ? " stale" : "") : "—";
}

// UPower's display device is one shared, event-driven aggregate. Direction
// comes from its state; a backend may provide unsigned watts or no rate.
function battery(device, states) {
    let mode;
    switch (device.state) {
    case states.Charging: mode = "charge"; break;
    case states.Discharging: mode = "drain"; break;
    case states.FullyCharged: mode = "full"; break;
    case states.Empty: mode = "empty"; break;
    case states.PendingCharge:
    case states.PendingDischarge: mode = "hold"; break;
    default: return { label: "BAT —" };
    }
    const p = device.percentage;
    // The optional Percentage property defaults to zero in Quickshell. Only
    // label an exact zero as measured when the device also reports Empty.
    const valid = Number.isFinite(p) && p <= 1 && (p > 0 || (p === 0 && mode === "empty"));
    const base = "BAT " + (valid ? Math.round(100 * p) + "%" : "—") + " ";
    const watts = Math.abs(device.changeRate);
    const rate = (mode === "charge" || mode === "drain") && Number.isFinite(watts) && watts >= 0.05
        ? base + (mode === "charge" ? "+" : "−") + watts.toFixed(1) + "W" : "";
    return { label: base + mode, rate: rate };
}
