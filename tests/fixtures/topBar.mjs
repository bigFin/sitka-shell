import { readFileSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';

// Exercise the shipped layout and instruments with isolated shell backends.
export function stageTopBar(dir, { liveUsage = false } = {}) {
    const read = name => readFileSync(new URL('../../' + name, import.meta.url), 'utf8');
    const write = (name, text) => writeFileSync(join(dir, name), text);
    write('TopBar.qml', read('modules/bar/TopBar.qml').replace(/^import (qs\.\S+|"\.\.\/\.\.\/config"|Quickshell|Quickshell\.Services\.UPower)$/gm,
        line => liveUsage && line === 'import qs.services' ? line : '')
        .replace('../../utils/scripts/dashboardData.js', 'dashboardData.js').replace(/required property (ShellScreen|PersistentProperties) /g, 'required property var '));
    write('dashboardData.js', read('utils/scripts/dashboardData.js'));
    for (const type of ['WeeklyDial', 'BatteryGauge']) write(`${type}.qml`, read(`modules/bar/${type}.qml`));
    write('BarConfig.qml', read('config/BarConfig.qml').replace('import Quickshell.Io', 'import QtQuick').replaceAll('JsonObject', 'QtObject'));
    write('StyledText.qml', 'import QtQuick\nText {}');
    write('StyledRect.qml', 'import QtQuick\nRectangle { property bool enableFillets; property real ditherRelief }');
    const doubles = {
        Probe: 'property int deviceStarts: 0',
        UPower: `Component.onCompleted: Probe.deviceStarts++; property QtObject displayDevice: QtObject { property bool ready; property bool isLaptopBattery; property bool isPresent; property int state; property real percentage; property real changeRate }`,
        UPowerDeviceState: 'enum State { Unknown, Charging, Discharging, Empty, FullyCharged, PendingCharge, PendingDischarge }',
        Config: 'property BarConfig bar: BarConfig {}; property var launcher: ({enabled:true}); property var services: ({useTwelveHourClock:false}); property var appearance: ({font:{family:{mono:"monospace"}}})',
        Colours: 'property var palette: ({m3onSurface:"white",m3error:"salmon",m3primary:"green",m3onPrimary:"black",m3outline:"gray",m3surfaceContainerHigh:"gray"}); property var tPalette: ({m3surface:"black",m3surfaceContainer:"gray"})',
        WorkspaceModel: 'function getWorkspacesForOutput(name) { return [{is_active:true},{is_active:false},{is_active:false}] }',
        Time: 'function format(fmt) { return fmt.includes("ddd") ? "Mon  12:00" : "12:00" }',
        SystemUsage: `property int cpuRefs; property int memoryRefs; property real cpuPerc: 0; property real memPerc: 0.75
            property var cpuState: ({available:false,stale:false}); property var memoryState: ({available:true,stale:true})
            function addRef(domain) { adjust(String(domain), 1) }
            function removeRef(domain) { adjust(String(domain), -1) }
            function adjust(domain, delta) { if(domain==='cpu') cpuRefs+=delta; else if(domain==='memory') memoryRefs+=delta; else throw Error(domain) }`,
    };
    if (!liveUsage) doubles.AgentUsage = `property var codexWeeklyQuota: null; property string codexError; property int codexRefs: 0
        function addCodexView() { codexRefs++ }
        function removeCodexView() { codexRefs-- }`;
    write('qmldir', [
        ...['TopBar', 'WeeklyDial', 'BatteryGauge', 'BarConfig', 'StyledText', 'StyledRect'].map(name => `${name} 1.0 ${name}.qml`),
        ...Object.keys(doubles).map(name => `singleton ${name} 1.0 ${name}.qml`),
    ].join('\n'));
    for (const [name, body] of Object.entries(doubles)) write(name + '.qml', `pragma Singleton\nimport QtQuick\nQtObject { ${body} }`);
}
