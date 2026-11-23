import assert from 'node:assert/strict';
import { spawn } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import test from 'node:test';

const executable = name => (process.env.PATH || '').split(':').filter(Boolean)
    .map(dir => join(dir, name)).find(existsSync);
const qs = process.env.QUICKSHELL || executable('quickshell');
const session = executable('dbus-run-session');
const busctl = executable('busctl');

function runSession(args, env) {
    return new Promise((resolve, reject) => {
        const child = spawn(session, args, { env, detached: true, stdio: ['ignore', 'pipe', 'pipe'] });
        let log = '';
        for (const stream of [child.stdout, child.stderr])
            stream.setEncoding('utf8').on('data', chunk => { log += chunk; });
        const watchdog = setTimeout(() => {
            // Kill the private bus and shell, not just the dbus-run-session parent.
            if (child.pid) {
                try { process.kill(-child.pid, 'SIGKILL'); }
                catch (error) { if (error.code !== 'ESRCH') reject(error); }
            }
        }, 6500);
        child.once('error', error => { clearTimeout(watchdog); reject(error); });
        child.once('close', (status, signal) => {
            clearTimeout(watchdog);
            resolve({ status, signal, log });
        });
    });
}

test('DND keeps notifications in history without showing or replaying muted popups', {
    skip: !qs || !session || !busctl ? 'requires Quickshell, dbus-run-session and busctl' : false,
}, async () => {
    const dir = mkdtempSync(join(tmpdir(), 'sn-'));
    try {
        for (const sub of ['services', 'config', 'run', 'home'])
            mkdirSync(join(dir, sub), { mode: 0o700 });
        const write = (path, text) => writeFileSync(join(dir, path), text);
        for (const name of ['Notifs', 'Time'])
            copyFileSync(new URL(`../services/${name}.qml`, import.meta.url), join(dir, `services/${name}.qml`));
        write('services/qmldir', 'singleton Notifs Notifs.qml\nsingleton Time Time.qml\n');
        write('config/qmldir', 'singleton Config Config.qml\n');
        write('config/Config.qml', `pragma Singleton
import QtQml
QtObject { property QtObject notifs: QtObject {
    property bool expire: false
    property int defaultExpireTimeout: 10000
} }`);
        // A private bus with no activation directories. The client cannot notify the live desktop.
        write('dbus.conf', `<busconfig>
  <type>session</type><auth>EXTERNAL</auth><listen>unix:abstract=sitka-${randomUUID()}</listen>
  <policy context="default">
    <allow send_destination="*"/><allow receive_sender="*"/><allow own="*"/>
  </policy>
</busconfig>`);
        write('shell.qml', `import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
ShellRoot {
    id: root
    property int step: 0
    readonly property var summaries: ["before", "muted", "after"]
    function snapshot(label: string): void {
        console.log("NOTIFS_STATE", JSON.stringify([label,
            Array.from(Notifs.list, item => item.summary),
            Array.from(Notifs.popups, item => item.summary)]));
    }
    Timer {
        running: true; interval: 25; repeat: true
        onTriggered: {
            if (!sender.running && root.step < root.summaries.length) sender.running = true;
        }
    }
    Process {
        id: sender
        command: [${JSON.stringify(busctl)}, '--address=' + Quickshell.env('DBUS_SESSION_BUS_ADDRESS'),
            '--auto-start=no', 'call', 'org.freedesktop.Notifications', '/org/freedesktop/Notifications',
            'org.freedesktop.Notifications', 'Notify', 'susssasa{sv}i',
            'Sitka DND test', '0', '', root.summaries[root.step] ?? '', '', '0',
            '1', 'urgency', 'y', root.step === 1 ? '2' : '1', '10000']
        onExited: (code, status) => {
            if (code !== 0) return;
            root.snapshot(root.summaries[root.step]);
            if (root.step === 0) Notifs.dnd = true;
            if (root.step === 1) {
                Notifs.dnd = false;
                root.snapshot('unmuted');
            }
            root.step += 1;
            if (root.step === root.summaries.length) Qt.quit();
        }
    }
    Component.onCompleted: Notifs.dnd = false;
    Timer { running: true; interval: 4000; onTriggered: Qt.quit() }
}`);
        const { status, signal, log } = await runSession(
            [`--config-file=${join(dir, 'dbus.conf')}`, '--', qs, '--no-color', '-p', dir], {
                PATH: process.env.PATH, LANG: 'C.UTF-8', HOME: join(dir, 'home'), XDG_RUNTIME_DIR: join(dir, 'run'),
                DBUS_SYSTEM_BUS_ADDRESS: `unix:path=${join(dir, 'disabled-system-bus')}`,
                QT_QPA_PLATFORM: 'offscreen', QT_QUICK_BACKEND: 'software', QT_QPA_PLATFORMTHEME: 'generic',
            });
        assert.equal(status, 0, `${signal ?? ''}\n${log}`);
        const states = Array.from(log.matchAll(/NOTIFS_STATE (\[[^\r\n]+\])/g), match => JSON.parse(match[1]));
        assert.equal(states.length, 4, log);
        assert.deepEqual(states, [
            ['before', ['before'], ['before']],
            ['muted', ['before', 'muted'], ['before']],
            ['unmuted', ['before', 'muted'], ['before']],
            ['after', ['before', 'muted', 'after'], ['before', 'after']],
        ]);
    } finally {
        rmSync(dir, { recursive: true, force: true });
    }
});
