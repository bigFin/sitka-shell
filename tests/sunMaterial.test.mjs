import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, readdirSync } from 'node:fs';
const read = path => readFileSync(new URL(`../${path}`, import.meta.url), 'utf8');

test('only the Sun preset opts into ordered surface texture', () => {
    assert.match(read('config/AppearanceConfig.qml'), /component Dithering: JsonObject \{\s*property bool enabled: false/);
    for (const file of readdirSync(new URL('../config/presets/', import.meta.url))) {
        const preset = JSON.parse(read(`config/presets/${file}`));
        if (file === 'sun-workstation.json') {
            assert.equal(preset.general.theme, 'SunWorkstation');
            assert.deepEqual(preset.appearance.dithering, { enabled: true, intensity: 0.32, pixelSize: 1 });
        } else assert.ok(!preset.appearance?.dithering?.enabled, file);
    }
    const surface = read('components/effects/DitherSurface.qml');
    assert.match(surface, /Config\.appearance\.dithering\.enabled && root\.intensity > 0/);
    assert.doesNotMatch(surface, /ShaderEffectSource|layer\.(?:enabled|effect)|Timer \{|FrameAnimation/);
    assert.match(read('components/controls/StyledTextField.qml'), /id: cursor\s+dithered: false/);
});

test('Sun launcher supporting text uses ink, not the outline or primary label role', () => {
    assert.match(read('services/Colours.qml'), /launcherSecondaryText: themeName === "SunWorkstation" \? palette\.m3onSurfaceVariant : palette\.m3outline/);
    for (const item of ['AppItem', 'ActionItem'])
        assert.match(read(`modules/launcher/items/${item}.qml`), /color: Colours\.launcherSecondaryText/);
    assert.match(read('modules/launcher/Content.qml'), /placeholderTextColor: Colours\.launcherSecondaryText/);
});

test('surface shader uses a static, balanced 4×4 ordered matrix', () => {
    const glsl = read('plugin/src/Sitka/shaders/dither.glsl');
    const matrix = glsl.match(/int\[16\]\(([\s\S]*?)\)/)[1].match(/\d+/g).map(Number);
    assert.deepEqual(matrix.sort((a, b) => a - b), Array.from({ length: 16 }, (_, i) => i));
    const frag = read('plugin/src/Sitka/shaders/dither-surface.frag');
    assert.doesNotMatch(frag, /sampler2D/);
    assert.match(read('plugin/src/Sitka/CMakeLists.txt'), /FILES shaders\/dither-surface\.frag/);
});
