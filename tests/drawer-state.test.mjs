import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import vm from 'node:vm';

const source = path => readFileSync(new URL('../' + path, import.meta.url), 'utf8');
const logic = vm.createContext({});
vm.runInContext(source('utils/scripts/drawerState.js').replace(/^\.pragma library\s*/, ''), logic);
const enabled = { launcher: true, session: true, dashboard: true };
function state() {
    const s = { keyboardDrawer: '', changingDrawer: false };
    // Mirror Drawers.qml's derived property used by the shipped IPC handler.
    Object.defineProperty(s, 'keyboardOwner', {
        enumerable: true,
        get: () => logic.keyboardOwner(s, enabled)
    });
    for (const drawer of ['launcher', 'session', 'dashboard']) {
        let visible = false;
        Object.defineProperty(s, drawer, {
            enumerable: true,
            get: () => visible,
            set(value) { visible = value; logic.changed(s, enabled, drawer); }
        });
    }
    return s;
}

test('replacement screen survives late destruction; unplug removes aliases and active fallback', () => {
    const old = {}, replacement = {}, second = {};
    const screens = new Map([['DP-1', replacement], ['DP-2', second]]);
    logic.unregister(screens, 'DP-1', old);
    assert.equal(logic.activeScreen(screens, 'DP-1'), replacement);
    logic.unregister(screens, 'DP-1', replacement);
    assert.equal(logic.activeScreen(screens, 'missing'), second);
    logic.unregister(screens, 'DP-2', second);
    assert.equal(logic.activeScreen(screens, 'missing'), null);
    const oldScreen = {}, newScreen = {};
    const bars = new Map([[oldScreen, old], [newScreen, replacement], ['DP-1', replacement]]);
    logic.unregisterValue(bars, old);
    assert.equal(bars.has(oldScreen), false);
    assert.equal(bars.get('DP-1'), replacement);
    logic.unregisterValue(bars, replacement);
    assert.equal(bars.size, 0);
});

test('hover is passive, explicit promotion acquires ownership, mouse leave preserves keyboard opening', () => {
    const s = state();
    logic.setDrawer(s, enabled, 'dashboard', true, 'passive');
    assert.equal(s.dashboard, true);
    assert.equal(logic.keyboardOwner(s, enabled), '');
    logic.setDrawer(s, enabled, 'dashboard', true, 'explicit');
    assert.equal(logic.keyboardOwner(s, enabled), 'dashboard');
    logic.setDrawer(s, enabled, 'dashboard', false, 'passive');
    logic.setDrawer(s, enabled, 'launcher', true, 'passive');
    assert.equal(s.dashboard, true);
    assert.equal(s.launcher, false);
    s.dashboard = false; // exact Escape contract
    assert.equal(logic.keyboardOwner(s, enabled), '');
});

test('legacy explicit clicks arbitrate simultaneous surfaces and screen ownership stays local', () => {
    const first = state(), second = state();
    first.launcher = true;
    first.session = true;
    assert.equal(first.launcher, false);
    assert.equal(logic.keyboardOwner(first, enabled), 'session');
    assert.equal(logic.keyboardOwner(second, enabled), '');
    logic.setDrawer(first, enabled, 'dashboard', true, 'explicit');
    assert.equal(first.session, false);
    assert.equal(logic.keyboardOwner(first, enabled), 'dashboard');
});

test('disabled panels neither open nor retain exclusive focus', () => {
    const s = state(), off = { ...enabled, dashboard: false };
    logic.setDrawer(s, off, 'dashboard', true, 'explicit');
    assert.equal(s.dashboard, false);
    assert.equal(s.keyboardDrawer, '');
    s.dashboard = true;
    assert.equal(logic.keyboardOwner(s, off), '');
    logic.changed(s, off, 'dashboard');
    assert.equal(s.dashboard, false);
    assert.equal(logic.keyboardOwner(s, off), '');
});

test('shipped IPC has no-screen behavior and explicit opening', () => {
    const qml = source('modules/Shortcuts.qml');
    const list = qml.match(/function list\(\): string \{([\s\S]*?)\n        \}/)[1];
    const toggle = qml.match(/function toggle\(drawer: string\): void \{([\s\S]*?)\n        \}/)[1];
    let active = null;
    const context = vm.createContext({ Visibilities: { getForActive: () => active }, console });
    vm.runInContext(`function list() {${list}}; function toggle(drawer) {${toggle}}`, context);
    assert.equal(context.list(), '');
    context.toggle('dashboard');
    active = state();
    active.setDrawer = (drawer, open, intent) => logic.setDrawer(active, enabled, drawer, open, intent);
    context.toggle('dashboard');
    assert.equal(active.keyboardDrawer, 'dashboard');
    context.toggle('dashboard');
    assert.equal(active.dashboard, false);
    logic.setDrawer(active, enabled, 'dashboard', true, 'passive');
    context.toggle('dashboard');
    assert.equal(active.dashboard, true, 'IPC promotes a preview rather than closing it');
    assert.equal(active.keyboardDrawer, 'dashboard');
});

test('shipped Interactions leave handler cannot dismiss an explicit dashboard', () => {
    const qml = source('modules/drawers/Interactions.qml');
    const body = qml.match(/onContainsMouseChanged: \{([\s\S]*?)\n    \}/)[1];
    const s = state();
    s.setDrawer = (drawer, open, intent) => logic.setDrawer(s, enabled, drawer, open, intent);
    s.dashboard = true;
    vm.runInNewContext(body, {
        containsMouse: false, osdShortcutActive: false, utilitiesShortcutActive: false,
        visibilities: s, osdHovered: false, popouts: { currentName: '' },
        Config: { bar: { revealMode: 'hover' } }, bar: {}
    });
    assert.equal(s.dashboard, true);
    assert.equal(s.keyboardDrawer, 'dashboard');
});

test('explicit acquisition revokes other monitor input, not visibility; stale unregister cannot revoke replacement', () => {
    const a = state(), old = state(), b = state();
    const screens = new Map([['A', a], ['B', b]]);
    const acquire = owner => logic.claimKeyboard(screens, owner);
    logic.setDrawer(a, enabled, 'dashboard', true, 'explicit', acquire);
    logic.setDrawer(b, enabled, 'launcher', true, 'explicit', acquire);
    assert.equal(a.dashboard, true);
    assert.equal(logic.keyboardOwner(a, enabled), '');
    assert.equal(logic.keyboardOwner(b, enabled), 'launcher');
    logic.unregister(screens, 'B', old);
    assert.equal(screens.get('B'), b);
    logic.setDrawer(a, enabled, 'dashboard', true, 'passive', acquire);
    assert.equal(logic.keyboardOwner(a, enabled), '');
    logic.setDrawer(a, enabled, 'dashboard', true, 'explicit', acquire);
    assert.equal(b.launcher, true);
    assert.equal(logic.keyboardOwner(b, enabled), '');
    assert.equal(logic.keyboardOwner(a, enabled), 'dashboard');
});
