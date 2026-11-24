import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, readFileSync, rmSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, delimiter } from 'node:path';
import { spawnSync } from 'node:child_process';

const qt = process.env.QMLTESTRUNNER || process.env.PATH.split(delimiter).map(d => join(d, 'qmltestrunner')).find(existsSync);

test('spruce geometry is deterministic, rooted, legible and bounded', { skip: qt ? false : 'Set QMLTESTRUNNER to run Qt Quick Test' }, () => {
    const dir = mkdtempSync(join(tmpdir(), 'sitka-shape-'));
    try {
        const src = readFileSync(new URL('../components/effects/SitkaTree.qml', import.meta.url), 'utf8')
            .replace(/^import (?!QtQuick).*$/gm, '')
            .replaceAll('Config.appearance.font.family.mono', '"monospace"')
            .replace(/Colours\.palette\.\w+/g, '"#badaba"');
        writeFileSync(join(dir, 'Tree.qml'), src);
        // Exercise the session's actual tree + MouseArea declaration in an 80 px Loader.
        const session = readFileSync(new URL('../modules/session/Content.qml', import.meta.url), 'utf8');
        const start = session.indexOf('sourceComponent: SitkaTree {');
        assert.notEqual(start, -1);
        let end = session.indexOf('{', start), depth = 1;
        while (++end < session.length && depth) {
            if (session[end] === '{') depth++;
            if (session[end] === '}') depth--;
        }
        assert.equal(depth, 0);
        const decoration = session.slice(start, end).replace('SitkaTree {', 'Tree {');
        writeFileSync(join(dir, 'tst_shape.qml'), `import QtQuick
import QtTest
TestCase {
    id: root; name: "Spruce"; when: windowShown; width: 160; height: 80; visible: true
    property var visibilities: ({session: true})
    Loader { id: host; x: 80; width: 80; height: 80; ${decoration} }
    function test_sessionClick() {
        compare(host.status, Loader.Ready); tryCompare(host.item, 'ready', true)
        compare(host.item.treeWidth, 7); compare(host.item.treeHeight, 8)
        const previous = host.item.seed; mouseClick(host.item, 40, 40); verify(host.item.seed !== previous)
    }
    Tree { id: tree; width: 80; height: 80; seed: 42 }
    function signature() {
        return JSON.stringify(tree.treeData.map(r => r.chars.map(c => [c.x, c.char, c.ink ?? String(c.color)])))
    }
    function test_liveTree() {
        tryCompare(tree, 'ready', true)
        tree.treeWidth = 7; tree.treeHeight = 8
        const before = signature(); tree.seed = 17; verify(signature() !== before)
        const column = tree.children[0], top = column.children[0], foot = column.children[7]
        verify(column.height * column.scale <= tree.height + 0.001)
        verify(column.width * column.scale <= tree.width + 0.001)
        const marker = top.children[0]; compare(marker.text, '╷')
        tree.needleColorLight = '#123456'; compare(String(marker.color), '#123456')
        const initial = top.mapToItem(tree, 0, 0).x, base = foot.mapToItem(tree, 0, 0).x
        tree.swayAmount = 1.5; verify(top.mapToItem(tree, 0, 0).x > initial); compare(foot.mapToItem(tree, 0, 0).x, base)
    }
    function test_staggeredBoughs() {
        // Look at the generated ink, not the choice of phase, glyph or silhouette.
        tree.treeWidth = 22; tree.treeHeight = 17
        for (let seed = 0; seed < 64; ++seed) {
            tree.seed = seed; tree.generateTree()
            let sides = new Set()
            for (const tier of tree.treeData.slice(3, -3)) {
                const cells = tier.chars
                if (cells.length < 3 || !cells.every((c, i) => !i || c.x === cells[i - 1].x + 1)) continue
                if (cells[0].ink === 'bark') sides.add('right')
                if (cells[cells.length - 1].ink === 'bark') sides.add('left')
            }
            verify(sides.size === 2, 'expected connected boughs with exposed wood on opposite sides at different heights; seed ' + seed)
        }
    }
    function test_clippedBoughEndsInLightTip() {
        tree.treeWidth = 25; tree.treeHeight = 18; tree.seed = 3
        tree.generateTree()
        const cells = tree.treeData[15].chars
        const tip = cells[cells.length - 1]
        compare(tip.x, 24)
        compare(tip.ink, 'light')
        verify(['⢠', '⡀', '⣀'].includes(tip.char), 'expected a right-hand tip glyph, got ' + tip.char)
    }
    function test_shape() {
        tryCompare(tree, 'ready', true)
        // Inspect the generated model without rebuilding the text scene 320 times.
        tree.ready = false
        for (let size of [[7,8], [11,12], [16,13], [25,18], [31,8]]) {
            tree.treeWidth = size[0]; tree.treeHeight = size[1]
            let seen = new Set()
            for (let seed = 0; seed < 64; ++seed) {
                tree.seed = seed; tree.generateTree()
                let sig = signature(); tree.generateTree(); compare(signature(), sig)
                seen.add(sig)
                compare(tree.treeData.length, size[1]); compare(tree.treeData[0].chars.length, 1)
                for (let y = 0; y < size[1]; ++y) {
                    let row = tree.treeData[y]; compare(row.row, y)
                    verify(row.chars.length > 0, 'missing leader or tier: ' + [seed,size,y]); let prev = -1
                    for (let c of row.chars) {
                        verify(Number.isInteger(c.x) && c.x > prev && c.x < size[0]); prev = c.x
                        compare([...c.char].length, 1)
                    }
                    if (y < size[1]-1) verify(row.chars.some(c => tree.treeData[y+1].chars.some(n => Math.abs(n.x-c.x) <= 1)), 'detached tier')
                }
                verify(tree.treeData[size[1]-2].chars.length <= 2, 'trunk wider than crown leader')
            }
            compare(seen.size, 64)
        }
    }
}`);
        const env = {...process.env, QT_QPA_PLATFORM: 'offscreen', QT_QPA_PLATFORMTHEME: 'generic', QT_STYLE_OVERRIDE: 'Fusion', QT_QUICK_BACKEND: 'software'};
        delete env.DISPLAY; delete env.WAYLAND_DISPLAY;
        const r = spawnSync(qt, ['-input', dir], {env, timeout: 30000, encoding: 'utf8'});
        console.log(r.stdout, r.stderr); assert.equal(r.status, 0);
    } finally { rmSync(dir, {recursive: true, force: true}); }
});
