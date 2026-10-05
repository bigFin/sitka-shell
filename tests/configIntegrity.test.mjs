import test from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, readFileSync } from 'node:fs';

const config = new URL('../config/', import.meta.url);
const source = name => readFileSync(new URL(name, config), 'utf8');

test('configuration singleton and appearance facade are present', () => {
    for (const name of ['Config.qml', 'Appearance.qml']) {
        assert.ok(existsSync(new URL(name, config)), `Missing required config/${name}`);
        assert.match(source(name), /pragma Singleton/);
    }
});

test('every configuration adapter type has its implementation', () => {
    // These are local QML types, not optional runtime shell.json preferences.
    const adapter = source('Config.qml');
    const types = [...adapter.matchAll(/property (\w+) \w+: \1 \{\}/g)].map(match => match[1]);
    assert.ok(types.length > 0, 'Config.qml must declare configuration sections');
    for (const type of types)
        assert.ok(existsSync(new URL(`${type}.qml`, config)), `Missing required config/${type}.qml`);
});

test('appearance facade references existing inline configuration types', () => {
    const facade = source('Appearance.qml');
    const refs = [...facade.matchAll(/property (\w+)\.(\w+) \w+:/g)];
    assert.ok(refs.length > 0, 'Appearance.qml must expose typed aliases');
    for (const [, owner, type] of refs)
        assert.match(source(`${owner}.qml`), new RegExp(`component ${type}:`), `${owner}.${type} must exist`);
});
