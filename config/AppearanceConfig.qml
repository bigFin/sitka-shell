import Quickshell.Io

JsonObject {
    property Rounding rounding: Rounding {}
    property Spacing spacing: Spacing {}
    property Padding padding: Padding {}
    property FontStuff font: FontStuff {}
    property Anim anim: Anim {}
    property Transparency transparency: Transparency {}

    component Rounding: JsonObject {
        property real scale: 0
        property int small: 0 * scale
        property int normal: 0 * scale
        property int large: 0 * scale
        property int full: 0 * scale
    }

    component FilletConfig: JsonObject {
        property real scale: 1
        property int small: 2 * scale    // 2px fillet for small elements
        property int normal: 4 * scale   // 4px fillet for normal elements  
        property int large: 6 * scale     // 6px fillet for large elements
        property int style: 1             // 0=radius, 1=chamfer, 2=fillet
    }

    component Spacing: JsonObject {
        property real scale: 1
        property int small: 7 * scale
        property int smaller: 10 * scale
        property int normal: 12 * scale
        property int larger: 15 * scale
        property int large: 20 * scale
    }

    component Padding: JsonObject {
        property real scale: 1
        property int small: 5 * scale
        property int smaller: 7 * scale
        property int normal: 10 * scale
        property int larger: 12 * scale
        property int large: 15 * scale
    }

    component FontFamily: JsonObject {
        property string sans: "Iosevka Term"
        property string mono: "Iosevka Term"
        property string material: "MaterialSymbolsSharp"
        property string clock: "Iosevka Term"
    }

    component FontSize: JsonObject {
        property real scale: 1
        property int ultraSmall: 8 * scale
        property int extraSmall: 10 * scale
        property int small: 11 * scale
        property int smaller: 12 * scale
        property int normal: 13 * scale
        property int larger: 15 * scale
        property int large: 18 * scale
        property int extraLarge: 28 * scale
    }

    component FontStuff: JsonObject {
        property FontFamily family: FontFamily {}
        property FontSize size: FontSize {}
    }

    property FilletConfig fillet: FilletConfig {}
    property int filletStyle: 1  // 0=radius, 1=chamfer, 2=fillet
    property bool enableFilletEffects: true

    component AnimCurves: JsonObject {
        property list<real> emphasized: [0, 0, 0.1, 1, 1, 1]
        property list<real> emphasizedAccel: [0.5, 0, 1, 1, 1, 1]
        property list<real> emphasizedDecel: [0, 0, 0.8, 1, 1, 1]
        property list<real> standard: [0, 0, 0.2, 1, 1, 1]
        property list<real> standardAccel: [0.5, 0, 1, 1, 1, 1]
        property list<real> standardDecel: [0, 0, 0.8, 1, 1, 1]
        property list<real> expressiveFastSpatial: [0.3, 0, 0.7, 1, 1, 1]
        property list<real> expressiveDefaultSpatial: [0.2, 0, 0.6, 1, 1, 1]
        property list<real> expressiveEffects: [0.1, 0, 0.5, 1, 1, 1]
    }

    component AnimDurations: JsonObject {
        property real scale: 0.5
        property int small: 200 * scale
        property int normal: 400 * scale
        property int large: 600 * scale
        property int extraLarge: 1000 * scale
        property int expressiveFastSpatial: 350 * scale
        property int expressiveDefaultSpatial: 500 * scale
        property int expressiveEffects: 200 * scale
    }

    component Anim: JsonObject {
        property AnimCurves curves: AnimCurves {}
        property AnimDurations durations: AnimDurations {}
    }

    component Transparency: JsonObject {
        property bool enabled: false
        property real base: 0.85
        property real layers: 0.4
    }
}
