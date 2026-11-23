import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';

const qs = process.env.QUICKSHELL || process.env.PATH.split(':').map(dir => join(dir, 'quickshell')).find(existsSync);
for (const scenario of ['handshake and reuse', 'retry rejected handshake', 'CLI unavailable']) {
    test(`Codex quota session: ${scenario}`, {
        skip: !qs && 'Quickshell is required for the service integration test',
    }, () => {
        const dir = mkdtempSync(join(tmpdir(), 'q-'));
        const rejectFirst = scenario === 'retry rejected handshake';
        const unavailable = scenario === 'CLI unavailable';
        try {
            for (const sub of ['services', 'utils/scripts', 'config', 'bin', 'run'])
                mkdirSync(join(dir, sub), { recursive: true, mode: 0o700 });
            for (const file of ['services/AgentUsage.qml', 'utils/scripts/shellParse.js'])
                copyFileSync(new URL('../' + file, import.meta.url), join(dir, file));
            writeFileSync(join(dir, 'services/qmldir'), 'singleton AgentUsage AgentUsage.qml\n');
            writeFileSync(join(dir, 'config/qmldir'), 'singleton Config Config.qml\n');
            writeFileSync(join(dir, 'config/Config.qml'), `pragma Singleton
import QtQml
QtObject { property QtObject services: QtObject { property QtObject agentUsage: QtObject {
    property bool showCodex: true; property bool showAdditionalCodexLimits: false; property bool showClaude: false
} } }`);
            // Isolate both ends of the pipe: use the shipped QML Process, never real credentials or a CLI on the host.
            writeFileSync(join(dir, 'bin/codex'), `#!${unavailable ? join(dir, 'not-installed') : process.execPath}
const { appendFileSync } = require('node:fs');
const { createInterface } = require('node:readline');
let rejected = false, reads = 0;
createInterface({ input: process.stdin }).on('line', line => {
    const { id, method } = JSON.parse(line);
    appendFileSync(process.env.TRACE, method + '\\n');
    if (method === 'initialized') return;
    const response = { id };
    if (method === 'initialize' && ${rejectFirst} && !rejected) {
        rejected = true; response.error = { message: 'try again' };
    } else if (method === 'initialize') response.result = {};
    else if (method === 'account/rateLimits/read') {
        response.result = { rateLimits: { primary: { usedPercent: ++reads } } };
    } else process.exit(2);
    setTimeout(() => console.log(JSON.stringify(response)), 60);
});`, { mode: 0o700 });
            writeFileSync(join(dir, 'shell.qml'), `import QtQuick
import Quickshell
import qs.services
ShellRoot {
    Component.onCompleted: AgentUsage.addView()
    Timer {
        running: true; interval: 10; repeat: true
        onTriggered: {
            if (!AgentUsage.loading && (${unavailable ? 'AgentUsage.codexError.length > 0' : 'AgentUsage.providers[0]?.usedPercent === 2'})) {
                console.log("QUOTA_OK"); Qt.quit(); return;
            }
            if (!${unavailable}) AgentUsage.refresh(); // bursts must share the pending handshake/read
        }
    }
    Timer { running: true; interval: 2000; onTriggered: Qt.quit() }
}`);
            const trace = join(dir, 'calls');
            writeFileSync(trace, '');
            const result = spawnSync(qs, ['--no-color', '-p', dir], { timeout: 5000, encoding: 'utf8', env: {
                HOME: dir, PATH: join(dir, 'bin'), TRACE: trace, XDG_RUNTIME_DIR: join(dir, 'run'), LANG: 'C.UTF-8',
                QT_QPA_PLATFORM: 'offscreen', QT_QUICK_BACKEND: 'software', QT_QPA_PLATFORMTHEME: 'generic',
            } });
            const log = result.stdout + result.stderr;
            assert.equal(result.status, 0, log);
            assert.match(log, /QUOTA_OK/, log);
            assert.deepEqual(readFileSync(trace, 'utf8').trim().split('\n').filter(Boolean), unavailable ? [] : [
                ...(rejectFirst ? ['initialize'] : []), 'initialize', 'initialized',
                'account/rateLimits/read', 'account/rateLimits/read',
            ]);
        } finally { rmSync(dir, { recursive: true, force: true }); }
    });
}
