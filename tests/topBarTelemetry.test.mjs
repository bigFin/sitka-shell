import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { delimiter, join } from 'node:path';

const read = name => readFileSync(new URL('../' + name, import.meta.url), 'utf8');
const qt = process.env.QMLTESTRUNNER || process.env.PATH.split(delimiter).map(p => join(p, 'qmltestrunner')).find(existsSync);
test('top bar: independent optional readings, geometry and per-view leases', { skip: !qt && 'run in nix develop for qmltestrunner' }, t => {
    const dir = mkdtempSync(join(tmpdir(), 'sitka-topbar-'));
    t.after(() => rmSync(dir, { recursive: true, force: true }));
    const write = (name, text) => writeFileSync(join(dir, name), text);
    // Keep the real bar, config defaults and formatter; isolate the shell backends.
    write('TopBar.qml', read('modules/bar/TopBar.qml').replace(/^import (qs\.\S+|"\.\.\/\.\.\/config"|Quickshell)$/gm, '')
        .replace('../../utils/scripts/dashboardData.js', 'dashboardData.js').replace(/required property (ShellScreen|PersistentProperties) /g, 'required property var '));
    write('dashboardData.js', read('utils/scripts/dashboardData.js'));
    write('BarConfig.qml', read('config/BarConfig.qml').replace('import Quickshell.Io', 'import QtQuick').replaceAll('JsonObject', 'QtObject'));
    write('StyledText.qml', 'import QtQuick\nText {}');
    write('StyledRect.qml', 'import QtQuick\nRectangle { property bool enableFillets; property real ditherRelief }');
    const doubles = {
        Config: 'property BarConfig bar: BarConfig {}; property var launcher: ({enabled:true}); property var services: ({useTwelveHourClock:false}); property var appearance: ({font:{family:{mono:"monospace"}}})',
        Colours: 'property var palette: ({m3onSurface:"white",m3primary:"green",m3onPrimary:"black",m3outline:"gray",m3surfaceContainerHigh:"gray"}); property var tPalette: ({m3surface:"black",m3surfaceContainer:"gray"})',
        WorkspaceModel: 'function getWorkspacesForOutput(name) { return [{is_active:true},{is_active:false},{is_active:false}] }',
        Time: 'function format(fmt) { return fmt.includes("ddd") ? "Mon  12:00" : "12:00" }',
        SystemUsage: `property int cpuRefs; property int memoryRefs; property real cpuPerc: 0; property real memPerc: 0.75
            property var cpuState: ({available:false,stale:false}); property var memoryState: ({available:true,stale:true})
            function addRef(domain) { adjust(String(domain), 1) }
            function removeRef(domain) { adjust(String(domain), -1) }
            function adjust(domain, delta) { if(domain==='cpu') cpuRefs+=delta; else if(domain==='memory') memoryRefs+=delta; else throw Error(domain) }`,
    };
    write('qmldir', Object.keys(doubles).map(name => `singleton ${name} 1.0 ${name}.qml`).join('\n'));
    for (const [name, body] of Object.entries(doubles)) write(name + '.qml', `pragma Singleton\nimport QtQuick\nQtObject { ${body} }`);
    write('tst_topBarTelemetry.qml', read('tests/qt/tst_topBarTelemetry.qml'));
    const env = { ...process.env, QT_QPA_PLATFORM: 'offscreen', QT_QPA_PLATFORMTHEME: 'generic', QT_QUICK_BACKEND: 'software' };
    delete env.WAYLAND_DISPLAY; delete env.DISPLAY;
    const result = spawnSync(qt, ['-input', dir], {env, encoding:'utf8', timeout:20000});
    const log = result.stdout + result.stderr;
    assert.ifError(result.error);
    assert.equal(result.status, 0, log);
    assert.doesNotMatch(log, /QWARN|ReferenceError|TypeError/);
});
