import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const read = path => readFileSync(new URL('../modules/dashboard/' + path, import.meta.url), 'utf8');
const refs = src => [...src.matchAll(/ServiceRef\s*\{\s*service:\s*([^\n}]+)/g)].map(m => m[1]);

test('only the visible media tab owns native audio analysis, without requiring an MPRIS player for the spectrum', () => {
    const expressions = refs(read('Media.qml'));
    assert.equal(expressions.length, 2);
    for (const active of [true, false]) for (const visible of [true, false]) {
        for (const hasGif of [true, false]) for (const playing of [true, false]) {
            const context = { root: {active, visible}, beatImage: {visible: visible && hasGif, playing}, Cava: {provider: 'spectrum'}, BeatTracker: 'beat' };
            const actual = expressions.map(e => vm.runInNewContext(e, context)).filter(Boolean).sort();
            const expected = [];
            if (active && visible) expected.push('spectrum');
            if (active && visible && hasGif && playing) expected.push('beat');
            assert.deepEqual(actual, expected.sort(), JSON.stringify(context));
        }
    }
});

test('overview media does not start a beat analyzer it never reads', () => {
    assert.doesNotMatch(read('dash/Media.qml'), /\bBeatTracker\b/);
});
