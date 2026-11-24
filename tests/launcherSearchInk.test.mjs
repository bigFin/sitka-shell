import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { runInNewContext } from 'node:vm';

const read = file => readFileSync(new URL(`../${file}`, import.meta.url), 'utf8');
// Resolve the launcher's local binding, or the inherited TextField binding on the old path.
const search = read('modules/launcher/Content.qml').split('id: search\n')[1].split('onPressed:')[0];
const ink = (search.match(/^            color: (.+)$/m) ?? read('components/controls/StyledTextField.qml').match(/^    color: (.+)$/m))[1];
const palette = Object.fromEntries([...read('services/M3Palette.qml').matchAll(/property color (\w+): "(#[a-f0-9]+)"/g)].map(([,role,value]) => [role,value]));
const light = read('services/Colours.qml').split('component EverforestLightPalette:')[1];
const lightInk = light.match(/property color fg: "(#[a-f0-9]+)"/)[1];
function colour(themeName, enabled, m3onSurface) {
    return runInNewContext(ink, { Colours: { themeName, transparency: { enabled }, palette: { ...palette, m3onSurface } } });
}
function luminance(hex) {
    const rgb = hex.slice(1).match(/../g).map(s => parseInt(s, 16) / 255)
        .map(v => v <= 0.04045 ? v / 12.92 : ((v + 0.055) / 1.055) ** 2.4);
    return rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722;
}

test('opaque EverforestLight launcher text passes on its inherited dark container', () => {
    const [lo, hi] = [colour('EverforestLight', false, lightInk), palette.m3surfaceContainer].map(luminance).sort((a,b) => a-b);
    const ratio = (hi + 0.05) / (lo + 0.05);
    assert.ok(ratio >= 4.5, `entered text contrast: ${ratio}:1`);
});

test('other themes and translucent EverforestLight retain normal entered-text ink', () => {
    for (const theme of ['EverforestDark', 'SunWorkstation', 'SunGraphite', 'RosePine', 'HighTest', 'Observatory'])
        assert.equal(colour(theme, false, '#102030'), '#102030', theme);
    assert.equal(colour('EverforestLight', true, lightInk), lightInk);
});
