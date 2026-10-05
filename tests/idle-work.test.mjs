import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, mkdtempSync, writeFileSync, existsSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, delimiter } from 'node:path';
import { fileURLToPath } from 'node:url';
import vm from 'node:vm';
import { spawnSync } from 'node:child_process';

const repoRoot = fileURLToPath(new URL('..', import.meta.url));
const sourceRoot = process.env.IDLE_SOURCE_ROOT || repoRoot;
const baseline = process.env.IDLE_BASELINE === '1';
const read = path => readFileSync(join(sourceRoot, path), 'utf8');
const qt = process.env.QMLTESTRUNNER || (process.env.PATH || '').split(delimiter)
    .map(dir => join(dir, 'qmltestrunner')).find(existsSync);
// Extract a balanced QML object, not a reimplementation of its running binding.
function object(source, type) {
    const start = source.indexOf(type + ' {');
    assert.ok(start >= 0);
    let depth = 0;
    for (let i = source.indexOf('{', start); i < source.length; i++) {
        if (source[i] === '{') depth++;
        if (source[i] === '}' && --depth === 0) return source.slice(start, i + 1);
    }
    throw new Error('Unclosed ' + type);
}

test('both media surfaces receive explicit activity from their containing dashboard', () => {
    const compact = object(readFileSync(join(repoRoot, 'modules/dashboard/Dash.qml'), 'utf8'), 'Media');
    const large = object(readFileSync(join(repoRoot, 'modules/dashboard/Content.qml'), 'utf8'), 'Media');
    const expression = source => {
        const binding = source.match(/active: ([^\n]+)/)?.[1];
        assert.ok(binding, 'Media requires an explicit activity binding');
        return binding;
    };
    for (const active of [false, true]) {
        assert.equal(vm.runInNewContext(expression(compact), {root: {systemUsageActive: active}}), active);
        for (const currentTab of [0, 1, 2]) {
            assert.equal(vm.runInNewContext(expression(large), {root: {expanded: active, state: {currentTab}}}), active && currentTab === 1);
        }
    }
});

test('idle work: shipped Qt timers and tree pause and resume without unloading', { skip: qt ? false : 'Install Qt 6 qmltestrunner or set QMLTESTRUNNER to run the runtime checks' }, () => {
    const dir = mkdtempSync(join(tmpdir(), 'sitka-idle-'));
    try {
        let tree = read('components/effects/SitkaTree.qml').replace(/^import (?!QtQuick).*$/gm, '');
        tree = tree.replace('id: root', `id: root
            ${baseline ? 'property bool active: true' : ''}
            property var Config: ({appearance: {font: {family: {mono: "monospace"}}}})
            property var Colours: ({palette: {m3tertiary: "brown", m3primary: "green", m3secondary: "green", m3primaryContainer: "green", m3tertiaryContainer: "brown"}})`);
        // QML property names must start lowercase; imported singleton doubles only.
        tree = tree.replaceAll('Config', 'config').replaceAll('Colours', 'colours');
        writeFileSync(join(dir, 'Tree.qml'), tree);
        let image = read('components/images/CyclingImage.qml').replace(/^import (?!QtQuick).*$/gm, '');
        image = image.replace(object(image, 'FileSystemModel'), 'QtObject { id: files; property var entries: [{path: ""}, {path: ""}] }');
        if (baseline) image = image.replace('id: root', 'id: root\n property bool active: true');
        writeFileSync(join(dir, 'Cycle.qml'), image);
        for (const [name, path] of [['Large', 'modules/dashboard/Media.qml'], ['Small', 'modules/dashboard/dash/Media.qml']]) {
            const timer = object(read(path), 'Timer').replaceAll('Players', 'players').replaceAll('Config', 'config');
            writeFileSync(join(dir, name + '.qml'), `import QtQuick
Item { id: root; property bool active: true; property bool playing: true; property int ticks: 0
property var players: ({active: {isPlaying: root.playing, positionChanged: () => root.ticks++}})
property var config: ({dashboard: {mediaUpdateInterval: 40}})
${timer}
}`);
        }
        const content = readFileSync(join(repoRoot, 'modules/dashboard/Content.qml'), 'utf8');
        const activity = object(content, 'Media').match(/active: ([^\n]+)/)?.[1];
        assert.ok(activity, 'large Media must receive explicit tab/expanded activity');
        writeFileSync(join(dir, 'tst_idle.qml'), `import QtQuick
import QtTest
TestCase {
 id: root
 name: "IdleWork"; when: windowShown; visible: true
 property bool expanded: false
 property var state: ({currentTab: 1})
 Item { id: wiring; property bool active: ${activity} }
 function test_activityWiring() {
   compare(wiring.visible, true);
   compare(wiring.active, false); // collapsed but still visible in persistent pane
   expanded = true;
   compare(wiring.active, true);
   state = ({currentTab: 0});
   compare(wiring.active, false);
   state = ({currentTab: 1});
   compare(wiring.active, true);
   expanded = false;
   compare(wiring.active, false);
 }
 property int changes: 0
 Tree { id: tree; animated: true; onSwayAmountChanged: changes++ }
 Tree { id: initiallyHidden; animated: true; active: false }
 Tree { id: growing; animated: true; growthProgress: 0; active: false }
 Cycle { id: cycle; dir: "/fixture"; cycleSeconds: 1 }
 Large { id: large }
 Small { id: small }
 function sample(label) {
   let before = [large.ticks, small.ticks, cycle.cycleIndex, changes];
   wait(1150);
   let counts = [large.ticks-before[0], small.ticks-before[1], cycle.cycleIndex-before[2], changes-before[3]];
   console.log(label + ": " + JSON.stringify(counts));
   return counts;
 }
 function test_lifecycle() {
   let frozen = initiallyHidden.swayAmount;
   let growth = growing.growthProgress;
   let counts = sample("open [large,small,cycle,sway]");
   for (let count of counts) verify(count > 0);
   ${baseline ? '' : 'compare(initiallyHidden.swayAmount, frozen); compare(growing.growthProgress, growth);'}
   large.active = small.active = tree.active = cycle.active = false;
   counts = sample("hidden");
   for (let count of counts) ${baseline ? 'verify(count > 0)' : 'compare(count, 0)'};
   let before = large.ticks;
   large.active = small.active = tree.active = cycle.active = true;
   wait(1);
   ${baseline ? '' : 'verify(large.ticks > before, "position refreshes immediately on resume");'}
   counts = sample("resumed");
   for (let count of counts) verify(count > 0);
   ${baseline ? '' : `large.visible = small.visible = tree.visible = cycle.visible = false;
   counts = sample("inherited visibility hidden");
   for (let count of counts) compare(count, 0);
   large.visible = small.visible = tree.visible = cycle.visible = true;`}
   large.playing = small.playing = false;
   tree.animated = false;
   cycle.cycleSeconds = 0;
   counts = sample("idle (paused media / static decorations)");
   for (let count of counts) compare(count, 0);
 }
}`);
        const env = { ...process.env, QT_QPA_PLATFORM: 'offscreen', QT_QPA_PLATFORMTHEME: 'generic', QT_STYLE_OVERRIDE: 'Fusion', QT_QUICK_BACKEND: 'software' };
        delete env.DISPLAY; delete env.WAYLAND_DISPLAY;
        const result = spawnSync(qt, ['-input', dir], { env, encoding: 'utf8', timeout: 20000 });
        console.log(result.stdout, result.stderr);
        assert.equal(result.status, 0);
    } finally { rmSync(dir, { recursive: true, force: true }); }
});
