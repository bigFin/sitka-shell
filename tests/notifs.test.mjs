import assert from 'node:assert/strict';
import { spawn, spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { randomUUID } from 'node:crypto';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import test from 'node:test';

const executable = name => (process.env.PATH || '').split(':').filter(Boolean)
    .map(dir => join(dir, name)).find(existsSync);
const qs = process.env.QUICKSHELL || executable('quickshell');
const session = executable('dbus-run-session');
const python = executable('python3');
const dbusNext = python && spawnSync(python, ['-c', 'import dbus_next']).status === 0;
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

const qmlImportPath = process.env.QML_IMPORT_PATH;
const skip = !qs || !session || !busctl || !qmlImportPath
    ? 'requires Quickshell, dbus-run-session, busctl and the built Sitka QML plugin' : false;
const externalSkip = skip || (!dbusNext ? 'requires Python dbus-next' : false);

async function withFixture(check) {
    const dir = mkdtempSync(join(tmpdir(), 'sn-'));
    try {
        for (const sub of ['services', 'config', 'run', 'home', 'activation'])
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
        // A private bus with only fixture activation services; never use the live desktop bus.
        write('dbus.conf', `<busconfig>
  <type>session</type><auth>EXTERNAL</auth><listen>unix:abstract=sitka-${randomUUID()}</listen>
  <servicedir>${join(dir, 'activation')}</servicedir>
  <policy context="default">
    <allow send_destination="*"/><allow receive_sender="*"/><allow own="*"/>
  </policy>
</busconfig>`);
        await check(dir, write);
    } finally {
        rmSync(dir, { recursive: true, force: true });
    }
}

async function runShell(dir, start = []) {
    const shell = [qs, '--no-color', '-p', dir];
    const { status, signal, log } = await runSession(
        [`--config-file=${join(dir, 'dbus.conf')}`, '--', ...start, ...shell], {
            PATH: process.env.PATH, LANG: 'C.UTF-8', HOME: join(dir, 'home'), XDG_RUNTIME_DIR: join(dir, 'run'),
            DBUS_SYSTEM_BUS_ADDRESS: `unix:path=${join(dir, 'disabled-system-bus')}`,
            QT_QPA_PLATFORM: 'offscreen', QT_QUICK_BACKEND: 'software', QT_QPA_PLATFORMTHEME: 'generic',
            QML_IMPORT_PATH: qmlImportPath, QML2_IMPORT_PATH: qmlImportPath,
        });
    assert.equal(status, 0, `${signal ?? ''}\n${log}`);
    return log;
}

test('DND keeps notifications in history without showing or replaying muted popups', { skip }, async () => withFixture(async (dir, write) => {
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
            if (root.step === 0) Notifs.setDnd(true);
            if (root.step === 1) {
                Notifs.setDnd(false);
                root.snapshot('unmuted');
            }
            root.step += 1;
            if (root.step === root.summaries.length) Qt.quit();
        }
    }
    Component.onCompleted: Notifs.setDnd(false);
    Timer { running: true; interval: 4000; onTriggered: Qt.quit() }
}`);
    const log = await runShell(dir);
    const states = Array.from(log.matchAll(/NOTIFS_STATE (\[[^\r\n]+\])/g), match => JSON.parse(match[1]));
    assert.equal(states.length, 4, log);
    assert.deepEqual(states, [
        ['before', ['before'], ['before']],
        ['muted', ['before', 'muted'], ['before']],
        ['unmuted', ['before', 'muted'], ['before']],
        ['after', ['before', 'muted', 'after'], ['before', 'after']],
    ]);
}));

const daemon = fileURLToPath(new URL('./notification-daemon.py', import.meta.url));

test('Sitka activates Hokum, controls DND and dismiss-all, and follows its new owner', { skip: externalSkip }, async () => withFixture(async (dir, write) => {
    write('activation/org.freedesktop.Notifications.service', `[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=${python} ${daemon} hokum
`);
    write('shell.qml', `import QtQuick
import Quickshell
import Quickshell.Io
import qs.services
ShellRoot {
    id: root
    property int step: 0
    Timer {
        interval: 20; running: true; repeat: true
        onTriggered: {
            if (root.step === 0 && Notifs.dndAvailable && Notifs.dnd) {
                console.log("HOKUM_INITIAL_DND");
                root.step++;
                external.running = true;
            } else if (root.step === 1 && Notifs.dndAvailable && !Notifs.dnd) {
                console.log("HOKUM_EXTERNAL_DND");
                root.step++;
                Notifs.setDnd(true);
            } else if (root.step === 2 && Notifs.dndAvailable && Notifs.dnd) {
                console.log("HOKUM_CHANGED_DND");
                root.step++;
                dismiss.running = true;
            } else if (root.step === 3 && !Notifs.dndAvailable) {
                console.log("HOKUM_OWNER_GONE");
                root.step++;
            } else if (root.step === 4 && Notifs.dndAvailable && Notifs.dnd) {
                console.log("HOKUM_NEW_OWNER_DND");
                Qt.quit();
            }
        }
    }
    Process {
        id: external
        command: ['touch', ${JSON.stringify(join(dir, 'home', 'flip-dnd'))}]
    }
    Process {
        id: dismiss
        command: [${JSON.stringify(qs)}, '-p', ${JSON.stringify(dir)}, 'ipc', 'call', 'notifs', 'clear']
        onExited: code => { if (code !== 0) Qt.exit(code); }
    }
    Timer { running: true; interval: 4000; onTriggered: Qt.quit() }
}`);
    const log = await runShell(dir);
    assert.match(log, /HOKUM_INITIAL_DND[\s\S]*HOKUM_EXTERNAL_DND[\s\S]*HOKUM_CHANGED_DND[\s\S]*HOKUM_OWNER_GONE[\s\S]*HOKUM_NEW_OWNER_DND/);
}));

test('Sitka leaves an already-running third-party daemon in charge', { skip: externalSkip }, async () => withFixture(async (dir, write) => {
    write('shell.qml', `import QtQuick
import Quickshell
import qs.services
ShellRoot {
    Component.onCompleted: console.log("DND_AVAILABLE", Notifs.dndAvailable)
    Timer { running: true; interval: 150; onTriggered: {
        console.log("DND_AVAILABLE", Notifs.dndAvailable);
        Qt.quit();
    } }
}`);
    const log = await runShell(dir, ['sh', '-ec', `
        "$1" "$2" other &
        pid=$!
        trap 'kill "$pid"' EXIT
        shift 2
        while [ ! -e "$HOME/ready" ]; do sleep 0.02; done
        "$@"
    `, 'notification-fixture', python, daemon]);
    assert.equal(Array.from(log.matchAll(/DND_AVAILABLE (\w+)/g), match => match[1]).join(' '), 'false false', log);
}));
