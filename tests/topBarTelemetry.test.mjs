import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { delimiter, join } from 'node:path';
import { stageTopBar } from './fixtures/topBar.mjs';

const qt = process.env.QMLTESTRUNNER || process.env.PATH.split(delimiter).map(p => join(p, 'qmltestrunner')).find(existsSync);
test('top bar: independent optional readings, geometry and per-view leases', { skip: !qt && 'run in nix develop for qmltestrunner' }, t => {
    const dir = mkdtempSync(join(tmpdir(), 'sitka-topbar-'));
    t.after(() => rmSync(dir, { recursive: true, force: true }));
    stageTopBar(dir);
    writeFileSync(join(dir, 'tst_topBarTelemetry.qml'), readFileSync(new URL('qt/tst_topBarTelemetry.qml', import.meta.url)));
    const env = { ...process.env, QT_QPA_PLATFORM: 'offscreen', QT_QPA_PLATFORMTHEME: 'generic', QT_QUICK_BACKEND: 'software' };
    delete env.WAYLAND_DISPLAY; delete env.DISPLAY;
    env.XDG_RUNTIME_DIR = env.XDG_CACHE_HOME = env.XDG_CONFIG_HOME = dir;
    env.DBUS_SYSTEM_BUS_ADDRESS = env.DBUS_SESSION_BUS_ADDRESS = 'unix:path=' + join(dir, 'no-bus');
    const result = spawnSync(qt, ['-input', dir], {env, encoding:'utf8', timeout:20000});
    const log = result.stdout + result.stderr;
    assert.ifError(result.error);
    assert.equal(result.status, 0, log);
    assert.doesNotMatch(log, /QWARN|ReferenceError|TypeError/);
});
