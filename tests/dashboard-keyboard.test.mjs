import test from 'node:test';
import assert from 'node:assert/strict';
import { readFile } from 'node:fs/promises';
import vm from 'node:vm';

const wrapper = await readFile(new URL('../modules/dashboard/Wrapper.qml', import.meta.url), 'utf8');
const tabs = await readFile(new URL('../modules/dashboard/Tabs.qml', import.meta.url), 'utf8');

// Execute the shipped handlers, not a separate interaction model. These tests
// cover handler decisions; compositor focus and Qt event propagation need Qt.
function handler(name, root) {
  const body = wrapper.match(new RegExp(`    Keys\\.${name}: (?:event => )?\\{([\\s\\S]*?)\\n    \\}`))?.[1];
  assert.ok(body, `missing ${name} handler`);
  return vm.runInNewContext(`(event) => { ${body} }`, {
    root,
    Qt: { Key_Space: 32, Key_Return: 16777220, Key_Enter: 16777221 },
  });
}

function dashboard(overrides = {}) {
  return { activeFocus: true, expanded: false, visibilities: { dashboard: true }, ...overrides };
}

for (const key of [32, 16777220, 16777221]) {
  test(`focused dashboard toggles once for key ${key}`, () => {
    const root = dashboard();
    const press = handler('onPressed', root);
    const event = { key, isAutoRepeat: false, accepted: false };
    press(event);
    assert.equal(root.expanded, true);
    assert.equal(event.accepted, true);
    press({ key, isAutoRepeat: true, accepted: false });
    assert.equal(root.expanded, true, 'held key must not toggle repeatedly');
    press(event);
    assert.equal(root.expanded, false);
  });
}

test('keys bubbling from child controls never toggle the dashboard', () => {
  const root = dashboard({ activeFocus: false });
  const press = handler('onPressed', root);
  for (const key of [32, 16777220, 16777221]) {
    const event = { key, accepted: false };
    press(event);
    assert.equal(root.expanded, false);
    assert.equal(event.accepted, false);
  }
});

test('a passive flash cannot expand through keyboard input', () => {
  const root = dashboard({ visibilities: { dashboard: false } });
  handler('onPressed', root)({ key: 32, accepted: false });
  assert.equal(root.expanded, false);
});

test('unrelated keys are left for normal navigation', () => {
  const root = dashboard();
  const event = { key: 16777217, accepted: false }; // Tab
  handler('onPressed', root)(event);
  assert.equal(root.expanded, false);
  assert.equal(event.accepted, false);
});

test('Escape closes and collapses an expanded dashboard', () => {
  const root = dashboard({ expanded: true });
  handler('onEscapePressed', root)({});
  assert.equal(root.visibilities.dashboard, false);
  assert.equal(root.expanded, false);
});

test('passive flashes do not request focus and focused tabs are highlighted', () => {
  const flashHandler = wrapper.slice(wrapper.indexOf('function onFocusSerialChanged'), wrapper.indexOf('Component.onCompleted'));
  assert.doesNotMatch(flashHandler, /forceActiveFocus|activeFocus\s*=\s*true/);
  assert.match(tabs, /tab\.activeFocus \? 0\.14/);
  assert.match(tabs, /text: tab\.text/);
});
