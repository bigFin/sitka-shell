import test from 'node:test';
import assert from 'node:assert/strict';
import fs from 'node:fs';
import path from 'node:path';
import { tmpdir } from 'node:os';
import { spawnSync } from 'node:child_process';
import vm from 'node:vm';

const source = fs.readFileSync(new URL('../utils/scripts/keyboardActivation.js', import.meta.url), 'utf8')
  .replace(/^\.pragma library\s*/m, '');
const context = {};
vm.runInNewContext(`${source}\nthis.invoke = invoke;`, context);

test('keyboard activation invokes once and ignores auto-repeat', () => {
  let calls = 0;
  assert.equal(context.invoke({ isAutoRepeat: false }, () => calls++), true);
  assert.equal(context.invoke({ isAutoRepeat: true }, () => calls++), false);
  assert.equal(context.invoke(null, () => calls++), true);
  assert.equal(calls, 2);
});

function findExecutable(name) {
  const extensions = process.platform === 'win32' ? (process.env.PATHEXT || '.EXE;.CMD;.BAT').split(';') : [''];
  for (const directory of (process.env.PATH || '').split(path.delimiter)) {
    if (!directory)
      continue;
    for (const extension of extensions) {
      const candidate = path.join(directory, `${name}${extension}`);
      try {
        fs.accessSync(candidate, fs.constants.X_OK);
        return candidate;
      } catch {
        // Continue searching PATH.
      }
    }
  }
  return null;
}

const qmltestrunner = process.env.QMLTESTRUNNER || findExecutable('qmltestrunner');
test('QtQuick affordance focus and activation harness', {
  skip: qmltestrunner ? false : 'qmltestrunner is not installed (set QMLTESTRUNNER to enable the isolated QtQuick test)',
}, () => {
  const dir = fs.mkdtempSync(path.join(tmpdir(), 'sitka-affordances-'));
  const write = (name, text) => fs.writeFileSync(path.join(dir, name), text);
  try {
    fs.mkdirSync(path.join(dir, 'doubles'));
    // Keep the shipped item tree, handlers and native Tab chain. Replace only
    // service imports, required service types and visual primitives with doubles.
    let rail = fs.readFileSync(new URL('../modules/controlcenter/NavRail.qml', import.meta.url), 'utf8')
      .replace(/^import (?:qs\.[^\n]+|Quickshell|"\.\.\/\.\.\/config")\n/gm, '')
      .replace('import QtQuick\n', 'import QtQuick\nimport "doubles"\n')
      .replace('../../utils/scripts/keyboardActivation.js', 'keyboardActivation.js')
      .replace('required property ShellScreen screen', 'required property var screen')
      .replace('required property Session session', 'required property var session')
      .replace('id: menuBtn', 'id: menuBtn; objectName: "menu"')
      .replace('sourceComponent: StyledRect {', 'sourceComponent: StyledRect { objectName: "float"')
      .replace('id: item', 'id: item; objectName: label');
    write('NavRail.qml', rail);
    write('keyboardActivation.js', fs.readFileSync(new URL('../utils/scripts/keyboardActivation.js', import.meta.url)));
    write('tst_affordanceKeyboard.qml', fs.readFileSync(new URL('./qt/tst_affordanceKeyboard.qml', import.meta.url)));
    write('tst_launcherFocus.qml', fs.readFileSync(new URL('./qt/tst_launcherFocus.qml', import.meta.url)));
    write('drawerState.js', fs.readFileSync(new URL('../utils/scripts/drawerState.js', import.meta.url)));
    const launcher = fs.readFileSync(new URL('../modules/launcher/Content.qml', import.meta.url), 'utf8');
    const start = launcher.indexOf('StyledTextField {');
    assert.ok(start >= 0);
    let depth = 0, end = start;
    for (let i = launcher.indexOf('{', start); i < launcher.length; i++) {
      if (launcher[i] === '{') depth++;
      if (launcher[i] === '}' && --depth === 0) { end = i + 1; break; }
    }
    assert.ok(end > start);
    const focusBinding = fs.readFileSync(new URL('../modules/launcher/Wrapper.qml', import.meta.url), 'utf8').match(/focus: ([^\n]+)/)[1];
    write('LauncherSearch.qml', `import QtQuick
import "doubles"
FocusScope {
 id: root; required property var visibilities; property int padding: 8
 width: 400; height: 100; focus: ${focusBinding}
 property alias field: search
 Item { id: searchIcon; width: 20 }
 Item { id: clearIcon; x: 380 }
 QtObject { id: list; property var currentList: null; property bool showWallpapers: false }
 ${launcher.slice(start, end)}
}`);
    write('StyledTextField.qml', fs.readFileSync(new URL('../components/controls/StyledTextField.qml', import.meta.url), 'utf8')
      .replace(/^import (?:"\.\."|qs\.services|"\.\.\/\.\.\/config")\n/gm, '')
      .replace('import QtQuick\n', 'import QtQuick\nimport "doubles"\n'));
    write('doubles/qmldir', 'singleton Config 1.0 Config.qml\nsingleton Colours 1.0 Colours.qml\nsingleton WindowFactory 1.0 WindowFactory.qml\n');
    write('doubles/Config.qml', `pragma Singleton
import QtQuick
QtObject { property var appearance: ({padding: {small: 4, normal: 8, large: 12, larger: 16}, spacing: {small: 4, normal: 8, large: 12}, rounding: {small: 4, normal: 8, full: 24}, font: {size: {small: 10, smaller: 10, large: 14}, family: {sans: "monospace"}}, anim: {durations: {small: 0, expressiveDefaultSpatial: 0}, curves: {expressiveDefaultSpatial: [0,0,1,1,1,1]}}}); property var launcher: ({actionPrefix: ":", vimKeybinds: false}) }`);
    write('doubles/Colours.qml', `pragma Singleton
import QtQuick
QtObject { property var palette: ({m3primary: "cyan", m3primaryContainer: "navy", m3onPrimaryContainer: "white", m3secondaryContainer: "grey", m3onSecondaryContainer: "white", m3onSurface: "white", m3outline: "grey"}) }`);
    write('doubles/WindowFactory.qml', `pragma Singleton
import QtQuick
QtObject { property int calls: 0; property var lastOptions; function create(parent, options) { calls++; lastOptions = options; } }`);
    write('StyledRect.qml', 'import QtQuick\nRectangle {}');
    write('StyledText.qml', 'import QtQuick\nText {}');
    write('MaterialIcon.qml', 'import QtQuick\nText { property real fill: 0 }');
    write('Anim.qml', 'import QtQuick\nNumberAnimation { duration: 0 }');
    write('CAnim.qml', 'import QtQuick\nColorAnimation { duration: 0 }');
    write('StateLayer.qml', 'import QtQuick\nItem { property real radius: 0; property color color: "transparent" }');
    const runnerArgs = ['-input', dir];
    for (const importPath of (process.env.QML_IMPORT_PATH || '').split(path.delimiter).filter(Boolean))
      runnerArgs.unshift('-import', importPath);
    const env = {...process.env, QT_QPA_PLATFORM: 'offscreen', QT_QPA_PLATFORMTHEME: 'generic', QT_STYLE_OVERRIDE: 'Fusion', QT_QUICK_BACKEND: 'software'};
    delete env.DISPLAY;
    delete env.WAYLAND_DISPLAY;
    const result = spawnSync(qmltestrunner, runnerArgs, { env, encoding: 'utf8', timeout: 20000 });
    console.log(result.stdout, result.stderr);
    assert.ifError(result.error);
    assert.equal(result.status, 0, `${result.stdout || ''}${result.stderr || ''}`);
    assert.doesNotMatch(`${result.stdout}${result.stderr}`, /QWARN|Unable to assign|ReferenceError|TypeError/);
  } finally {
    fs.rmSync(dir, {recursive: true, force: true});
  }
});
