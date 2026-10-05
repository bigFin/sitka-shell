import test from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';

const read = path => readFileSync(new URL(`../${path}`, import.meta.url), 'utf8');
const colours = read('services/Colours.qml');
const component = name => {
    const match = colours.match(new RegExp(`component ${name}: \\w+ \\{([\\s\\S]*?)\\n    \\}`));
    assert.ok(match, `${name} component exists`);
    return match[1];
};
const palette = Object.fromEntries([...component('ObservatoryPalette').matchAll(/(\w+): "(#[\da-f]{6})"/g)].map(m => [m[1], m[2]]));
const luminance = hex => {
    assert.match(hex, /^#[\da-f]{6}$/);
    const rgb = hex.slice(1).match(/../g).map(c => parseInt(c, 16) / 255)
        .map(c => c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4);
    return rgb[0] * 0.2126 + rgb[1] * 0.7152 + rgb[2] * 0.0722;
};
const contrast = (a, b) => {
    const l = [luminance(palette[a]), luminance(palette[b])].sort((a, b) => b - a);
    return (l[0] + 0.05) / (l[1] + 0.05);
};

// Read the shipped QML values rather than maintaining a second test palette.
test('Observatory explicitly supplies every M3, terminal and compatibility role', () => {
    const roles = [...component('M3Palette').matchAll(/property color (\w+):/g)].map(m => m[1]);
    assert.deepEqual(Object.keys(palette).sort(), roles.sort());
    assert.equal(Object.keys(palette).length, [...component('ObservatoryPalette').matchAll(/(\w+):/g)].length);
});

test('Observatory normal text pairs meet 4.5:1 on opaque surfaces', () => {
    const pairs = [
        ['m3onBackground', 'm3background'], ['m3inverseOnSurface', 'm3inverseSurface'],
        ['m3onSurfaceVariant', 'm3surfaceVariant'], ['m3inversePrimary', 'm3inverseSurface']
    ];
    for (const surface of ['Surface', 'SurfaceDim', 'SurfaceBright', 'SurfaceContainerLowest',
        'SurfaceContainerLow', 'SurfaceContainer', 'SurfaceContainerHigh', 'SurfaceContainerHighest']) {
        pairs.push(['m3onSurface', `m3${surface[0].toLowerCase()}${surface.slice(1)}`]);
    }
    for (const accent of ['Primary', 'Secondary', 'Tertiary', 'Error']) {
        const role = accent.toLowerCase();
        pairs.push([`m3on${accent}`, `m3${role}`], [`m3on${accent}Container`, `m3${role}Container`]);
        if (accent !== 'Error') {
            for (const background of [`m3${role}Fixed`, `m3${role}FixedDim`]) {
                pairs.push([`m3on${accent}Fixed`, background], [`m3on${accent}FixedVariant`, background]);
            }
        }
    }
    for (const [fg, bg] of pairs) assert.ok(contrast(fg, bg) >= 4.5, `${fg}/${bg}: ${contrast(fg, bg).toFixed(2)}:1`);
});

test('Observatory status accents and outlines remain legible on instrument panels', () => {
    for (const surface of ['m3surface', 'm3surfaceContainer', 'm3surfaceContainerHighest']) {
        for (const fg of ['success', 'warning', 'info', 'error', 'm3primary', 'm3secondary', 'm3tertiary']) {
            assert.ok(contrast(fg, surface) >= 4.5, `${fg}/${surface}: ${contrast(fg, surface).toFixed(2)}:1`);
        }
        assert.ok(contrast('m3outline', surface) >= 3, `outline/${surface}`);
    }
    const surfaces = ['m3surfaceContainerLowest', 'm3surfaceDim', 'm3surface', 'm3surfaceContainerLow',
        'm3surfaceContainer', 'm3surfaceContainerHigh', 'm3surfaceContainerHighest', 'm3surfaceBright'];
    const levels = surfaces.map(role => luminance(palette[role]));
    assert.deepEqual(levels, [...levels].sort((a, b) => a - b));
});

test('Observatory is opt-in and does not mutate the legacy palette', () => {
    assert.match(colours, /knownThemes: \[[^\]]*"Observatory"/);
    assert.match(colours, /readonly property M3Palette palette: themeName === "Observatory" \? observatory : current/);
    assert.match(colours, /readonly property M3Palette observatory: ObservatoryPalette \{\}/);
    assert.match(colours, /Config.general.theme \|\| "EverforestDark"/);
    assert.doesNotMatch(colours, /current\.\w+\s*=\s*observatory/);
    const preset = JSON.parse(read('config/presets/observatory.json'));
    assert.deepEqual(preset, { general: { theme: 'Observatory' }, appearance: { transparency: { mode: 'opaque' } } });
});

test('Observatory wallpaper is self-contained static vector artwork', () => {
    const svg = read('assets/wallpapers/observatory.svg');
    assert.match(svg, /viewBox="0 0 3840 2160"/);
    assert.match(svg, /<title>.+<\/title>/);
    assert.doesNotMatch(svg, /<\s*(?:script|animate\w*|set|foreignObject|image)\b|\bon\w+\s*=|(?:href|src)\s*=/i);
    assert.doesNotMatch(svg, /url\((?!#)/);
    // Qt SVG Tiny omits these features; keep contours/grid as pre-clipped paths.
    assert.doesNotMatch(svg, /<(?:clipPath|pattern|filter)\b/);
});
