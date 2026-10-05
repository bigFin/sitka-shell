pragma Singleton

import qs.config
import qs.utils
import Quickshell
import QtQuick
import "../utils/scripts/weatherLifecycle.js" as WeatherLifecycle
import "../utils/scripts/dashboardData.js" as DashboardData

Singleton {
    id: root

    property bool available: false
    property bool loading: false
    property bool stale: false
    property var lastUpdate: null

    property string city
    property var cc
    property var forecast
    readonly property string icon: cc ? Icons.getWeatherIcon(cc.weatherCode) : "cloud_alert"
    readonly property string description: cc?.weatherDesc?.[0]?.value ?? qsTr("No weather")
    readonly property string temp: DashboardData.temperature(Config.services.useFahrenheit ? cc?.temp_F : cc?.temp_C, Config.services.useFahrenheit)
    readonly property string feelsLike: DashboardData.temperature(Config.services.useFahrenheit ? cc?.FeelsLikeF : cc?.FeelsLikeC, Config.services.useFahrenheit)
    readonly property int humidity: cc?.humidity ?? 0

    readonly property var lifecycle: WeatherLifecycle.create({
        status: state => {
            root.available = state.available;
            root.loading = state.loading;
            root.stale = state.stale;
            root.lastUpdate = state.lastUpdate;
        },
        configuredCity: () => Config.services.weatherLocation,
        city: () => root.city,
        setCity: value => { root.city = value; },
        now: () => Date.now(),
        request: (url, success, failure) => Requests.get(url, success, failure),
        apply: (current, nextForecast) => {
            root.cc = current;
            root.forecast = nextForecast;
        }
    })

    function reload(): void {
        lifecycle.reload();
    }

    onCityChanged: lifecycle.refresh(city)
}
