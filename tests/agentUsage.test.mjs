import test from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { copyFileSync, existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join } from 'node:path';
import { tmpdir } from 'node:os';
import { stageTopBar } from './fixtures/topBar.mjs';

const qs = process.env.QUICKSHELL || process.env.PATH.split(':').map(dir => join(dir, 'quickshell')).find(existsSync);
for (const scenario of ['handshake and reuse', 'retry rejected handshake', 'CLI unavailable', 'weekly zero then only a model limit', 'shared bar and dashboard demand', 'failed read and disconnected CLI', 'silent CLI expires the dial and recovers']) {
    test(`Codex quota session: ${scenario}`, {
        skip: !qs && 'Quickshell is required for the service integration test',
    }, t => {
        const dir = mkdtempSync(join(tmpdir(), 'q-'));
        const rejectFirst = scenario === 'retry rejected handshake';
        const unavailable = scenario === 'CLI unavailable';
        const weekly = scenario === 'weekly zero then only a model limit';
        const shared = scenario === 'shared bar and dashboard demand';
        const failed = scenario === 'failed read and disconnected CLI';
        const stalled = scenario === 'silent CLI expires the dial and recovers';
        try {
            for (const sub of ['services', 'utils/scripts', 'config', 'bin', 'run'])
                mkdirSync(join(dir, sub), { recursive: true, mode: 0o700 });
            for (const file of ['services/AgentUsage.qml', 'utils/scripts/shellParse.js'])
                copyFileSync(new URL('../' + file, import.meta.url), join(dir, file));
            if (stalled) {
                mkdirSync(join(dir, 'bar'));
                stageTopBar(join(dir, 'bar'), { liveUsage: true });
            }
            writeFileSync(join(dir, 'services/qmldir'), 'singleton AgentUsage AgentUsage.qml\n');
            writeFileSync(join(dir, 'config/qmldir'), 'singleton Config Config.qml\n');
            writeFileSync(join(dir, 'config/Config.qml'), `pragma Singleton
import QtQml
QtObject { property QtObject services: QtObject { property QtObject agentUsage: QtObject {
    property bool showCodex: true; property bool showAdditionalCodexLimits: ${weekly}; property bool showClaude: ${shared}
} } }`);
            // Isolate both ends of the pipe: use the shipped QML Process, never real credentials or a CLI on the host.
            writeFileSync(join(dir, 'bin/codex'), `#!${unavailable ? join(dir, 'not-installed') : process.execPath}
const { appendFileSync } = require('node:fs');
const { createInterface } = require('node:readline');
let rejected = false, reads = 0, stalledId;
createInterface({ input: process.stdin }).on('line', line => {
    const { id, method } = JSON.parse(line);
    appendFileSync(process.env.TRACE, method + '\\n');
    if (method === 'initialized') return;
    const response = { id };
    if (method === 'initialize' && ${rejectFirst} && !rejected) {
        rejected = true; response.error = { message: 'try again' };
    } else if (method === 'initialize') response.result = {};
    else if (method === 'account/rateLimits/read') {
        ++reads;
        if (${stalled} && reads === 2) { stalledId = id; return; }
        const week = { usedPercent: ${weekly} ? 0 : reads, windowDurationMins: 10080 };
        response.result = { rateLimits: { primary: week } };
        // The old response arrives while the recovery request is in flight.
        if (${stalled} && reads === 3) console.log(JSON.stringify({ id: stalledId,
            result: { rateLimits: { primary: { ...week, usedPercent: 99 } } } }));
        if (${failed} && reads === 2) response.error = { message: 'fixture read failed' };
        if (${failed} && reads === 3) process.exit(1);
        if (${weekly} && reads > 1) response.result.rateLimitsByLimitId = {
            spark: { secondary: { usedPercent: 85, windowDurationMins: 10080 } }
        };
    } else process.exit(2);
    setTimeout(() => console.log(JSON.stringify(response)), 60);
});`, { mode: 0o700 });
            // Record an attempted Claude command without resolving any real CLI.
            writeFileSync(join(dir, 'bin/timeout'), `#!${process.execPath}\nrequire('node:fs').appendFileSync(process.env.TRACE, 'claude\\n');`, { mode: 0o700 });
            writeFileSync(join(dir, 'shell.qml'), shared || stalled ? readFileSync(new URL(shared ? 'qt/agentUsageDemand.qml' : 'qt/agentUsageStall.qml', import.meta.url)) : `import QtQuick
import Quickshell
import qs.services
ShellRoot {
    id: root
    property bool sawWeeklyZero: false
    property bool awaitingRetry: false
    Component.onCompleted: AgentUsage.addView()
    Timer {
        running: true; interval: 10; repeat: true
        onTriggered: {
            ${failed ? `if (root.awaitingRetry && !AgentUsage.codexLoading && AgentUsage.codexError === "Codex CLI unavailable") {
                console.log("QUOTA_OK"); Qt.quit(); return;
            }
            if (AgentUsage.codexError === "fixture read failed" && !root.awaitingRetry) {
                AgentUsage.refresh(); // A pending retry is not fresh data.
                if (AgentUsage.codexError !== "fixture read failed") { Qt.quit(); return; }
                root.awaitingRetry = true;
            } else if (!root.awaitingRetry && !AgentUsage.codexLoading && AgentUsage.codexWeeklyQuota) AgentUsage.refresh();
            return;` : ''}
            ${weekly ? `if (!AgentUsage.loading) {
                const quota = AgentUsage.codexWeeklyQuota;
                if (quota?.usedPercent === 0 && quota.resetsAt === null)
                    root.sawWeeklyZero = true;
                else if (root.sawWeeklyZero && quota === null && AgentUsage.providers[0]?.id === "codex-spark") {
                    console.log("QUOTA_OK"); Qt.quit(); return;
                }
            }` : ''}
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
            if (stalled) {
                for (const line of log.split('\n').filter(line => /qml: (VALID|PENDING|EXPIRED|RETRY|RECOVERED|WATCHDOG)/.test(line)))
                    t.diagnostic(line.trim());
            }
            assert.equal(result.status, 0, log);
            assert.match(log, /QUOTA_OK/, log);
            if (stalled) {
                assert.match(log, /PENDING Codex 1% used \/ 1 \/ Codex weekly: 1% used/);
                assert.match(log, /EXPIRED Codex — \/ -1 \/ Codex weekly usage unavailable/);
                assert.match(log, /RETRY -1/);
                assert.match(log, /RECOVERED Codex 3% used \/ 3 \/ Codex weekly: 3% used/);
            }
            assert.deepEqual(readFileSync(trace, 'utf8').trim().split('\n').filter(Boolean), unavailable ? [] : [
                ...(rejectFirst ? ['initialize'] : []), 'initialize', 'initialized',
                'account/rateLimits/read', ...(shared ? ['claude'] : []), 'account/rateLimits/read',
                ...(failed || stalled ? ['account/rateLimits/read'] : []),
            ]);
        } finally { rmSync(dir, { recursive: true, force: true }); }
    });
}
