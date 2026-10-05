.pragma library

function create(options) {
    let locationGeneration = 0;
    let weatherGeneration = 0;
    let locationCancel = null;
    let locationPending = false;
    let weatherCancel = null;
    let pendingCity = null;
    let lastLocationAttempt = null;
    let available = false;
    let stale = false;
    let lastUpdate = null;
    let lastGoodCity = null;

    function publish() {
        if (options.status)
            options.status({ available: available, loading: locationPending || pendingCity !== null,
                stale: stale, lastUpdate: lastUpdate });
    }

    function failed() {
        stale = available;
        publish();
    }

    function refresh(city) {
        city = (city || "").trim();
        if (pendingCity === city)
            return;
        const generation = ++weatherGeneration;
        if (weatherCancel)
            weatherCancel();
        weatherCancel = null;
        pendingCity = null;
        if (!city) {
            publish();
            return;
        }
        pendingCity = city;
        if (available && city !== lastGoodCity)
            stale = true;
        publish();
        const cancel = options.request("https://wttr.in/" + encodeURIComponent(city) + "?format=j1", function(text) {
            if (generation !== weatherGeneration || city !== (options.city() || "").trim())
                return;
            pendingCity = null;
            weatherCancel = null;
            try {
                const json = JSON.parse(text);
                const current = json && json.current_condition;
                const cc = Array.isArray(current) ? current[0] : null;
                if (cc && !Array.isArray(cc) && typeof cc === "object"
                        && cc.weatherCode != null && cc.temp_C != null
                        && String(cc.weatherCode).trim() !== "" && String(cc.temp_C).trim() !== ""
                        && Number.isFinite(Number(cc.weatherCode)) && Number.isFinite(Number(cc.temp_C))
                        && Array.isArray(json.weather)) {
                        options.apply(cc, json.weather);
                        available = true;
                        lastGoodCity = city;
                        stale = false;
                        lastUpdate = options.now();
                        publish();
                        return;
                    }
            } catch (e) {}
            failed();
        }, function() {
            if (generation === weatherGeneration) {
                pendingCity = null;
                weatherCancel = null;
                failed();
            }
        });
        if (pendingCity === city && generation === weatherGeneration)
            weatherCancel = cancel;
    }

    function reload() {
        const configured = (options.configuredCity() || "").trim();
        if (configured) {
            ++locationGeneration;
            if (locationCancel)
                locationCancel();
            locationCancel = null;
            locationPending = false;
            options.setCity(configured);
            refresh(configured);
            return;
        }
        // Refresh cached weather even while geolocation is being refreshed.
        refresh(options.city());
        const now = options.now();
        if (locationPending || (lastLocationAttempt !== null && now - lastLocationAttempt < 900000))
            return;
        lastLocationAttempt = now; // Failure is also bounded by the existing 15-minute cadence.
        const generation = ++locationGeneration;
        locationPending = true;
        publish();
        const cancel = options.request("https://ipinfo.io/json", function(text) {
            if (generation !== locationGeneration)
                return;
            locationCancel = null;
            locationPending = false;
            if ((options.configuredCity() || "").trim()) {
                publish();
                return;
            }
            try {
                const json = JSON.parse(text);
                const city = json && typeof json.city === "string" ? json.city.trim() : "";
                if (city) {
                    options.setCity(city);
                    refresh(city);
                    publish();
                    return;
                }
            } catch (e) {}
            failed();
        }, function() {
            if (generation === locationGeneration) {
                locationCancel = null;
                locationPending = false;
                failed();
            }
        });
        if (locationPending && generation === locationGeneration)
            locationCancel = cancel;
    }
    return { reload: reload, refresh: refresh };
}
