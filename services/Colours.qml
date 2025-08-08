pragma Singleton
pragma ComponentBehavior: Bound

import qs.utils
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Controls

Singleton {
    id: root

    property bool showPreview
    property string scheme
    property string flavour
    readonly property bool light: showPreview ? previewLight : currentLight
    property bool currentLight
    property bool previewLight
    readonly property M3Palette palette: showPreview ? preview : current
    readonly property M3TPalette tPalette: M3TPalette {}
    readonly property M3Palette current: M3Palette {}
    readonly property M3Palette preview: M3Palette {}
    readonly property Transparency transparency: Transparency {}

    function alterColour(c: color, a: real, layer: int): color {
        const luminance = Math.sqrt(0.299 * (c.r ** 2) + 0.587 * (c.g ** 2) + 0.114 * (c.b ** 2));
        const scale = (luminance + (!light || layer == 1 ? 1 : -layer / 2) * (light ? 0.1 : 0.3) * (1 - transparency.base)) / luminance;
        const r = Math.max(0, Math.min(1, c.r * scale));
        const g = Math.max(0, Math.min(1, c.g * scale));
        const b = Math.max(0, Math.min(1, c.b * scale));
        return Qt.rgba(r, g, b, a);
    }

    function layer(c: color, layer: var): color {
        if (!transparency.enabled)
            return c;

        return layer === 0 ? Qt.alpha(c, transparency.base) : alterColour(c, transparency.layers, layer ?? 1);
    }

    function on(c: color): color {
        if (c.hslLightness < 0.5)
            return Qt.hsla(c.hslHue, c.hslSaturation, 0.9, 1);
        return Qt.hsla(c.hslHue, c.hslSaturation, 0.1, 1);
    }

    function load(data: string, isPreview: bool): void {
        const colours = isPreview ? preview : current;
        const scheme = JSON.parse(data);

        if (!isPreview) {
            root.scheme = scheme.name;
            flavour = scheme.flavour;
            currentLight = scheme.mode === "light";
        } else {
            previewLight = scheme.mode === "light";
        }

        for (const [name, colour] of Object.entries(scheme.colours)) {
            const propName = `m3${name}`;
            if (colours.hasOwnProperty(propName))
                colours[propName] = `#${colour}`;
        }
    }

    function setMode(mode: string): void {
        Quickshell.execDetached(["caelestia", "scheme", "set", "--notify", "-m", mode]);
    }

    FileView {
        path: `${Paths.stringify(Paths.state)}/scheme.json`
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.load(text(), false)
    }

    component Transparency: QtObject {
        property bool enabled: false
        property real base: 0.8
        property real layers: 0.75
    }

    component M3TPalette: M3Palette {
        m3primary_paletteKeyColor: root.layer(root.palette.m3primary_paletteKeyColor)
        m3secondary_paletteKeyColor: root.layer(root.palette.m3secondary_paletteKeyColor)
        m3tertiary_paletteKeyColor: root.layer(root.palette.m3tertiary_paletteKeyColor)
        m3neutral_paletteKeyColor: root.layer(root.palette.m3neutral_paletteKeyColor)
        m3neutral_variant_paletteKeyColor: root.layer(root.palette.m3neutral_variant_paletteKeyColor)
        m3background: root.layer(root.palette.m3background, 0)
        m3onBackground: root.layer(root.palette.m3onBackground)
        m3surface: root.layer(root.palette.m3surface, 0)
        m3surfaceDim: root.layer(root.palette.m3surfaceDim, 0)
        m3surfaceBright: root.layer(root.palette.m3surfaceBright, 0)
        m3surfaceContainerLowest: root.layer(root.palette.m3surfaceContainerLowest)
        m3surfaceContainerLow: root.layer(root.palette.m3surfaceContainerLow)
        m3surfaceContainer: root.layer(root.palette.m3surfaceContainer)
        m3surfaceContainerHigh: root.layer(root.palette.m3surfaceContainerHigh)
        m3surfaceContainerHighest: root.layer(root.palette.m3surfaceContainerHighest)
        m3onSurface: root.layer(root.palette.m3onSurface)
        m3surfaceVariant: root.layer(root.palette.m3surfaceVariant, 0)
        m3onSurfaceVariant: root.layer(root.palette.m3onSurfaceVariant)
        m3inverseSurface: root.layer(root.palette.m3inverseSurface, 0)
        m3inverseOnSurface: root.layer(root.palette.m3inverseOnSurface)
        m3outline: root.layer(root.palette.m3outline)
        m3outlineVariant: root.layer(root.palette.m3outlineVariant)
        m3shadow: root.layer(root.palette.m3shadow)
        m3scrim: root.layer(root.palette.m3scrim)
        m3surfaceTint: root.layer(root.palette.m3surfaceTint)
        m3primary: root.layer(root.palette.m3primary)
        m3onPrimary: root.layer(root.palette.m3onPrimary)
        m3primaryContainer: root.layer(root.palette.m3primaryContainer)
        m3onPrimaryContainer: root.layer(root.palette.m3onPrimaryContainer)
        m3inversePrimary: root.layer(root.palette.m3inversePrimary)
        m3secondary: root.layer(root.palette.m3secondary)
        m3onSecondary: root.layer(root.palette.m3onSecondary)
        m3secondaryContainer: root.layer(root.palette.m3secondaryContainer)
        m3onSecondaryContainer: root.layer(root.palette.m3onSecondaryContainer)
        m3tertiary: root.layer(root.palette.m3tertiary)
        m3onTertiary: root.layer(root.palette.m3onTertiary)
        m3tertiaryContainer: root.layer(root.palette.m3tertiaryContainer)
        m3onTertiaryContainer: root.layer(root.palette.m3onTertiaryContainer)
        m3error: root.layer(root.palette.m3error)
        m3onError: root.layer(root.palette.m3onError)
        m3errorContainer: root.layer(root.palette.m3errorContainer)
        m3onErrorContainer: root.layer(root.palette.m3onErrorContainer)
        m3primaryFixed: root.layer(root.palette.m3primaryFixed)
        m3primaryFixedDim: root.layer(root.palette.m3primaryFixedDim)
        m3onPrimaryFixed: root.layer(root.palette.m3onPrimaryFixed)
        m3onPrimaryFixedVariant: root.layer(root.palette.m3onPrimaryFixedVariant)
        m3secondaryFixed: root.layer(root.palette.m3secondaryFixed)
        m3secondaryFixedDim: root.layer(root.palette.m3secondaryFixedDim)
        m3onSecondaryFixed: root.layer(root.palette.m3onSecondaryFixed)
        m3onSecondaryFixedVariant: root.layer(root.palette.m3onSecondaryFixedVariant)
        m3tertiaryFixed: root.layer(root.palette.m3tertiaryFixed)
        m3tertiaryFixedDim: root.layer(root.palette.m3tertiaryFixedDim)
        m3onTertiaryFixed: root.layer(root.palette.m3onTertiaryFixed)
        m3onTertiaryFixedVariant: root.layer(root.palette.m3onTertiaryFixedVariant)
    }

    component M3Palette: QtObject {
        property color m3primary_paletteKeyColor: "#7870AB"
        property color m3secondary_paletteKeyColor: "#78748A"
        property color m3tertiary_paletteKeyColor: "#976A7D"
        property color m3neutral_paletteKeyColor: "#79767D"
        property color m3neutral_variant_paletteKeyColor: "#797680"
        property color m3background: "#141318"
        property color m3onBackground: "#E5E1E9"
        property color m3surface: "#141318"
        property color m3surfaceDim: "#141318"
        property color m3surfaceBright: "#3A383E"
        property color m3surfaceContainerLowest: "#0E0D13"
        property color m3surfaceContainerLow: "#1C1B20"
        property color m3surfaceContainer: "#201F25"
        property color m3surfaceContainerHigh: "#2B292F"
        property color m3surfaceContainerHighest: "#35343A"
        property color m3onSurface: "#E5E1E9"
        property color m3surfaceVariant: "#48454E"
        property color m3onSurfaceVariant: "#C9C5D0"
        property color m3inverseSurface: "#E5E1E9"
        property color m3inverseOnSurface: "#312F36"
        property color m3outline: "#938F99"
        property color m3outlineVariant: "#48454E"
        property color m3shadow: "#000000"
        property color m3scrim: "#000000"
        property color m3surfaceTint: "#C8BFFF"
        property color m3primary: "#C8BFFF"
        property color m3onPrimary: "#30285F"
        property color m3primaryContainer: "#473F77"
        property color m3onPrimaryContainer: "#E5DEFF"
        property color m3inversePrimary: "#5F5791"
        property color m3secondary: "#C9C3DC"
        property color m3onSecondary: "#312E41"
        property color m3secondaryContainer: "#484459"
        property color m3onSecondaryContainer: "#E5DFF9"
        property color m3tertiary: "#ECB8CD"
        property color m3onTertiary: "#482536"
        property color m3tertiaryContainer: "#B38397"
        property color m3onTertiaryContainer: "#000000"
        property color m3error: "#EA8DC1"
        property color m3onError: "#690005"
        property color m3errorContainer: "#93000A"
        property color m3onErrorContainer: "#FFDAD6"
        property color m3primaryFixed: "#E5DEFF"
        property color m3primaryFixedDim: "#C8BFFF"
        property color m3onPrimaryFixed: "#1B1149"
        property color m3onPrimaryFixedVariant: "#473F77"
        property color m3secondaryFixed: "#E5DFF9"
        property color m3secondaryFixedDim: "#C9C3DC"
        property color m3onSecondaryFixed: "#1C192B"
        property color m3onSecondaryFixedVariant: "#484459"
        property color m3tertiaryFixed: "#FFD8E7"
        property color m3tertiaryFixedDim: "#ECB8CD"
        property color m3onTertiaryFixed: "#301121"
        property color m3onTertiaryFixedVariant: "#613B4C"

        property color archBlue: "#1793D1"
        property color success: "#4CAF50"
        property color warning: "#FF9800"
        property color info: "#2196F3"
        property color error: "#F2B8B5"

        property color rosewater: "#B8C4FF"
        property color flamingo: "#DBB9F8"
        property color pink: "#F3B3E3"
        property color mauve: "#D0BDFE"
        property color red: "#F8B3D1"
        property color maroon: "#F6B2DA"
        property color peach: "#E4B7F4"
        property color yellow: "#C3C0FF"
        property color green: "#ADC6FF"
        property color teal: "#D4BBFC"
        property color sky: "#CBBEFF"
        property color sapphire: "#BDC2FF"
        property color blue: "#C7BFFF"
        property color lavender: "#EAB5ED"
    }
}
