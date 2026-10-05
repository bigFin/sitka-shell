import { it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';
const data = vm.createContext({});
vm.runInContext(readFileSync(new URL('../utils/scripts/dashboardData.js', import.meta.url), 'utf8').replace(/^\.pragma library\s*/, ''), data);
it('dashboard missing readings differ from valid zero and retain stale last-good timestamps', () => {
    let state = data.initial();
    assert.equal(data.percent(0, state), '—');
    state = data.transition(state, 'loading', 1);
    assert.equal(state.loading, true);
    state = data.transition(state, 'failure', 2);
    assert.equal(state.available, false);
    state = data.transition(state, 'success', 3);
    assert.equal(data.percent(0, state), '0%');
    state = data.transition(state, 'failure', 4);
    assert.equal(data.percent(0, state), '0% stale');
    assert.equal(state.lastUpdate, 3);
    state = data.transition(state, 'success', 5);
    assert.equal(state.stale, false);
    assert.equal(state.lastUpdate, 5);
});
it('late resource completion retains its timestamp but cannot clear paused staleness', () => {
    const qml = readFileSync(new URL('../services/SystemUsage.qml', import.meta.url), 'utf8');
    const body = qml.match(/function updateState\(domain: string, outcome: string\): void \{([\s\S]*?)\n    \}/)[1];
    for (const domain of ['cpu', 'memory', 'storage']) {
        for (const reason of ['inactive', 'idle']) {
            const key = domain + 'State';
            const root = {[key]: data.transition(data.initial(), 'success', 1), [domain + 'Active']: true};
            const IdleService = {isIdle: false};
            const context = vm.createContext({root, IdleService, DashboardData: data, Date: {now: () => 10}});
            vm.runInContext(`function updateState(domain, outcome) {${body}}`, context);
            context.updateState(domain, 'loading');
            if (reason === 'inactive') root[domain + 'Active'] = false;
            else IdleService.isIdle = true;
            context.updateState(domain, 'paused');
            context.updateState(domain, 'success');
            assert.equal(root[key].available, true);
            assert.equal(root[key].lastUpdate, 10);
            assert.equal(root[key].stale, true);
            assert.equal(root[key].loading, false);
            root[domain + 'Active'] = true;
            IdleService.isIdle = false;
            context.updateState(domain, 'loading');
            assert.equal(root[key].stale, true, 'refresh keeps retained data stale');
            context.updateState(domain, 'success');
            assert.equal(root[key].stale, false, 'active fresh completion recovers');
        }
    }
});
it('temperature preserves valid zero but never fabricates an absent reading', () => {
    for (const value of [null, undefined, '', ' ', 'bad']) assert.equal(data.temperature(value, false), '—');
    assert.equal(data.temperature('0', false), '0°C');
    assert.equal(data.temperature(0, true), '0°F');
});
it('UTC handles midnight/noon, minutes and twelve-hour preference, opt-in by default', () => {
    assert.equal(data.utc(new Date('2026-01-01T00:05:00Z'), false), '00:05 UTC');
    assert.equal(data.utc(new Date('2026-01-01T00:05:00Z'), true), '12:05 AM UTC');
    assert.equal(data.utc(new Date('2026-01-01T12:05:00Z'), true), '12:05 PM UTC');
    assert.match(readFileSync(new URL('../config/DashboardConfig.qml', import.meta.url), 'utf8'), /property bool showUtc: false/);
});
