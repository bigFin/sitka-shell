import { describe, it } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

function load(file) {
    const context = vm.createContext({});
    vm.runInContext(readFileSync(new URL('../utils/scripts/' + file, import.meta.url), 'utf8').replace(/^\.pragma library\s*/, ''), context);
    return context;
}
const requests = load('requestLifecycle.js');
const weather = load('weatherLifecycle.js');
const cpu = load('cpuSampling.js');
const shared = load('shellParse.js');

function transport() {
    let expire;
    let stopped = 0;
    let aborts = 0;
    const events = [];
    const xhr = {
        open() {}, send() {},
        abort() {
            aborts++;
            assert.equal(this.onreadystatechange, null);
            assert.equal(this.onerror, null);
        }
    };
    const cancel = requests.get(xhr, 'url', text => events.push(text), reason => events.push(reason), (fn, ms) => {
        assert.equal(ms, 15000);
        expire = fn;
        return () => stopped++;
    }, 15000);
    return { xhr, cancel, expire: () => expire(), events, counts: () => [stopped, aborts] };
}

describe('Requests shipped lifecycle', () => {
    it('detaches before abort; success and late events settle exactly once', () => {
        const t = transport();
        const late = t.xhr.onreadystatechange;
        Object.assign(t.xhr, { readyState: 4, status: 200, responseText: 'good' });
        late(); t.cancel(); t.expire(); late();
        assert.deepEqual(t.events, ['good']);
        assert.deepEqual(t.counts(), [1, 1]);
    });
    for (const mode of ['http', 'network', 'timeout', 'cancel']) {
        it(mode + ' clears resources without success', () => {
            const t = transport();
            if (mode === 'http') {
                Object.assign(t.xhr, { readyState: 4, status: 503 });
                t.xhr.onreadystatechange();
            } else if (mode === 'network') t.xhr.onerror();
            else if (mode === 'timeout') t.expire();
            else t.cancel();
            t.cancel(); t.expire();
            assert.deepEqual(t.events, [{ http: 'http:503', network: 'network', timeout: 'timeout', cancel: 'cancelled' }[mode]]);
            assert.deepEqual(t.counts(), [1, 1]);
        });
    }
    it('handles synchronous send failures and supports success-only callers', () => {
        let failed;
        let stopped = false;
        const x = { open() {}, send() { throw Error('send'); }, abort() {} };
        requests.get(x, 'url', () => assert.fail(), reason => failed = reason, () => () => stopped = true, 15000);
        assert.equal(failed, 'exception');
        assert.equal(stopped, true);
        const t = { open() {}, send() {}, abort() {} };
        const cancel = requests.get(t, 'url', () => assert.fail(), undefined, () => () => {}, 15000);
        cancel();
    });
});

function weatherHarness() {
    const h = { configured: '', city: '', now: 0, pending: [], applied: [] };
    h.controller = weather.create({
        status: state => { h.status = state; },
        configuredCity: () => h.configured, city: () => h.city,
        setCity: city => { h.city = city; h.controller.refresh(city); },
        now: () => h.now,
        apply: (cc, forecast) => h.applied.push([cc, forecast]),
        request: (url, success, failure) => {
            const request = { url, success, failure, cancelled: false };
            h.pending.push(request);
            return () => { request.cancelled = true; failure('cancelled'); };
        }
    });
    return h;
}
const good = value => JSON.stringify({ current_condition: [{ temp_C: value, weatherCode: '113' }], weather: [] });

describe('Weather shipped lifecycle', () => {
    it('refreshes unchanged configured city and coalesces overlapping reloads', () => {
        const h = weatherHarness(); h.configured = 'A/B ?# Montréal';
        h.controller.reload(); h.controller.reload();
        assert.equal(h.pending.length, 1);
        assert.equal(h.pending[0].url, 'https://wttr.in/A%2FB%20%3F%23%20Montr%C3%A9al?format=j1');
        h.pending[0].success(good(10)); h.controller.reload();
        assert.equal(h.pending.length, 2);
        h.pending[1].success(good(11));
        assert.equal(h.applied.at(-1)[0].temp_C, 11);
    });
    it('cancels superseded weather and ignores a late success or failure', () => {
        const h = weatherHarness(); h.configured = 'Old'; h.controller.reload();
        h.configured = 'New'; h.controller.reload();
        assert.equal(h.pending[0].cancelled, true);
        h.pending[0].success(good(1)); h.pending[0].failure('timeout');
        h.controller.reload(); assert.equal(h.pending.length, 2);
        h.pending[1].success(good(2));
        assert.equal(h.applied.length, 1);
        assert.equal(h.applied[0][0].temp_C, 2);
    });
    it('does not overwrite configured location with stale geolocation', () => {
        const h = weatherHarness(); h.controller.reload();
        h.configured = 'Chosen'; h.controller.reload();
        assert.equal(h.pending[0].cancelled, true);
        h.pending[0].success('{"city":"Stale"}');
        assert.equal(h.city, 'Chosen');
        assert.equal(h.pending.length, 2);
    });
    it('rechecks configuration even before the next reload', () => {
        const h = weatherHarness(); h.controller.reload();
        h.configured = 'Chosen'; h.pending[0].success('{"city":"Stale"}');
        assert.equal(h.city, '');
        assert.equal(h.pending.length, 1);
    });
    it('refreshes cached auto city and bounds location failures to the existing cadence', () => {
        const h = weatherHarness(); h.city = 'Cached'; h.controller.reload();
        assert.equal(h.pending.length, 2);
        h.pending[0].success(good(4)); h.pending[1].failure('timeout');
        h.now = 100; h.controller.reload();
        assert.equal(h.pending.length, 3); // weather, not geolocation
        h.pending[2].success(good(5));
        h.now = 900000; h.controller.reload();
        assert.equal(h.pending.length, 5);
        assert.equal(h.pending[4].url, 'https://ipinfo.io/json');
    });
    it('keeps last-good data on malformed, missing and failed weather', () => {
        const h = weatherHarness(); h.configured = 'City'; h.controller.reload();
        h.pending[0].success(good(3));
        for (const text of ['null', '{}', '{"current_condition":[],"weather":[]}', '{"current_condition":[{}],"weather":[]}', '{"current_condition":[{"temp_C":"bad","weatherCode":"113"}],"weather":[]}', 'broken']) {
            h.controller.reload(); h.pending.at(-1).success(text);
        }
        h.controller.reload(); h.pending.at(-1).failure('http:500');
        assert.equal(h.applied.length, 1);
    });
    it('synchronous request failures do not leave geolocation permanently pending', () => {
        let now = 0;
        let attempts = 0;
        const controller = weather.create({
            configuredCity: () => '', city: () => '', setCity: () => {},
            now: () => now, apply: () => assert.fail(),
            request: (url, success, failure) => {
                attempts++;
                failure('exception');
                return () => failure('cancelled');
            }
        });
        controller.reload(); controller.reload();
        assert.equal(attempts, 1);
        now = 900000; controller.reload();
        assert.equal(attempts, 2);
    });
    it('empty and invalid location responses never request a blank weather URL', () => {
        const h = weatherHarness(); h.controller.reload(); h.controller.reload();
        assert.equal(h.pending.length, 1);
        h.pending[0].success('{"city":42}');
        h.controller.reload(); assert.equal(h.pending.length, 1);
    });
});

const stat = values => 'cpu  ' + values.join(' ') + '\ncpu0 0 0 0 0\n';
function sample(values, previous, now) {
    return cpu.sample(stat(values), previous, now, shared.calculateCpuUsage);
}
describe('SystemUsage shipped CPU sampling', () => {
    it('baselines first sample, counts steal but not guest, and treats iowait as idle', () => {
        const a = sample([100, 0, 50, 800, 20, 0, 0, 5, 10, 0], null, 0);
        assert.equal(a.usage, null);
        const b = sample([160, 0, 70, 810, 30, 0, 0, 15, 30, 0], a.previous, 3000);
        assert.ok(Math.abs(b.usage - 90 / 110) < 1e-10);
    });
    it('rebaselines wake gaps, deactivation, clock jumps, counter resets and zero deltas', () => {
        const first = sample([10, 0, 10, 80], null, 0).previous;
        assert.equal(sample([20, 0, 20, 160], first, 9000).usage, null);
        assert.equal(sample([20, 0, 20, 160], null, 3000).usage, null);
        assert.equal(sample([20, 0, 20, 160], first, -1).usage, null);
        assert.equal(sample([1, 0, 1, 8], first, 3000).usage, null);
        assert.equal(sample([10, 0, 10, 80], first, 3000).usage, null);
    });
    it('drops malformed samples without publishing zero usage', () => {
        for (const text of ['', 'cpu 1 2 3', 'cpu 1 2 3 4x', 'cpu 1 -2 3 4', 'cpu 99999999999999999999 2 3 4']) {
            const result = cpu.sample(text, null, 0, shared.calculateCpuUsage);
            assert.equal(result.usage, null);
            assert.equal(result.previous, null);
        }
    });
    it('QML uses helpers and resets baselines when CPU polling stops', () => {
        const qml = readFileSync(new URL('../services/SystemUsage.qml', import.meta.url), 'utf8');
        assert.match(qml, /onRunningChanged: root.cpuSample = null/);
        assert.match(qml, /CpuSampling.sample\(text\(\), root.cpuSample, Date.now\(\), ShellParse.calculateCpuUsage\)/);
    });
});

it('weather publishes loading, missing, valid zero, failed refresh and recovery metadata', () => {
    const h = weatherHarness(); h.configured = 'City';
    h.controller.reload();
    assert.equal(h.status.loading, true);
    assert.equal(h.status.available, false);
    h.pending.at(-1).failure('timeout');
    assert.equal(h.status.loading, false);
    assert.equal(h.status.available, false);
    h.now = 10; h.controller.reload(); h.pending.at(-1).success(good(0));
    assert.equal(h.status.available, true);
    assert.equal(h.status.lastUpdate, 10);
    h.controller.reload(); h.pending.at(-1).success('{}');
    assert.equal(h.status.stale, true);
    assert.equal(h.status.lastUpdate, 10);
    assert.equal(h.applied.at(-1)[0].temp_C, 0);
    h.now = 20; h.controller.reload(); h.pending.at(-1).success(good(2));
    assert.equal(h.status.stale, false);
    assert.equal(h.status.lastUpdate, 20);
});
