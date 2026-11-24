import test from 'node:test';
import assert from 'node:assert/strict';
import { cpSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

// Exercise the real JSON adapter, Border and StyledRect. Only the desktop's
// palette service is replaced; no compositor or personal settings are needed.
test('perimeter paint follows showStroke without changing the layout thickness', {
    skip: process.env.SITKA_LIB_DIR ? false : 'run in nix develop for Quickshell and the Sitka plugin',
}, t => {
    const dir = mkdtempSync(join(tmpdir(), 'ss-'));
    t.after(() => rmSync(dir, { recursive: true, force: true }));
    const write = (file, data) => writeFileSync(join(dir, file), data);
    for (const sub of ['config', 'components', 'utils', 'modules/drawers/Border.qml'])
        cpSync(new URL(`../${sub}`, import.meta.url), join(dir, sub), { recursive: true });
    mkdirSync(join(dir, 'services'));
    write('services/Colours.qml', 'pragma Singleton\nimport QtQuick\nQtObject { readonly property bool sunMaterial: false; readonly property var tPalette: ({m3surface: "red"}) }');
    write('shell.qml', `import QtQuick
import Quickshell
import qs.config
import qs.modules.drawers
import qs.components.effects
ShellRoot {
    Item {
        id: scene; width: 93; height: 71
        Border { id: perimeter; bar: scene }
        DrawerPlate { id: hud; width: 50; height: 20; dockAtTop: true; dockOverhang: 4 }
        DrawerPlate { id: launcher; width: 50; height: 20; dockAtTop: false; dockOverhang: 4 }
        Timer {
            interval: 20; running: true; repeat: true
            onTriggered: {
                if (Config.border.thickness !== 7) return; // Wait for the actual file load.
                const paint = perimeter.children[0];
                const joined = [hud.childAt(-3, -6), launcher.childAt(53, 26)].map(item => item !== null);
                const outside = hud.childAt(-6, -6) !== null || launcher.childAt(56, 26) !== null;
                console.log("STROKE:", JSON.stringify([paint.visible ? paint.border.width : 0, perimeter.width, perimeter.height, ...joined, outside]));
                Qt.quit();
            }
        }
    }
}`);
    const env = { ...process.env, HOME: dir, SITKA_CONFIG_DIR: dir, QT_QPA_PLATFORM: 'offscreen',
        QT_QUICK_BACKEND: 'software', QT_QPA_PLATFORMTHEME: 'generic', QT_STYLE_OVERRIDE: 'Fusion',
        DBUS_SESSION_BUS_ADDRESS: `unix:path=${dir}/no-bus`, DBUS_SYSTEM_BUS_ADDRESS: `unix:path=${dir}/no-bus` };
    for (const key of ['DISPLAY', 'WAYLAND_DISPLAY', 'NIRI_SOCKET', 'HYPRLAND_INSTANCE_SIGNATURE']) delete env[key];
    for (const key of ['XDG_CONFIG_HOME', 'XDG_RUNTIME_DIR', 'XDG_CACHE_HOME', 'XDG_STATE_HOME', 'XDG_DATA_HOME']) {
        env[key] = join(dir, key === 'XDG_RUNTIME_DIR' ? 'r' : key);
        mkdirSync(env[key], { mode: 0o700 });
    }
    for (const [showStroke, expected] of [[undefined, 7], [false, 0], [true, 7]]) {
        write('shell.json', JSON.stringify({ border: { thickness: 7, showStroke } }));
        const result = spawnSync('qs', ['--no-color', '-p', dir], { env, timeout: 8000, encoding: 'utf8' });
        const log = result.stdout + result.stderr;
        assert.equal(result.status, 0, result.error?.message + '\n' + log);
        assert.deepEqual(JSON.parse(log.match(/STROKE: (\[[^\]]+\])/)?.[1] ?? 'null'),
            [expected, 93, 71, showStroke === false, showStroke === false, false], `showStroke=${showStroke}\n${log}`);
    }
});
