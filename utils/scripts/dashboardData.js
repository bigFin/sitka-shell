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
