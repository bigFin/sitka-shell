/* Procedural Sitka spruce, drawn one monospace cell at a time. */
import QtQuick
import qs.services
import "../../config"

Item {
    id: root

    property int seed: Math.floor(Math.random() * 10000)
    property bool animated: false
    // Callers supply panel/tab activity; keep animation state while hidden.
    property bool active: true
    property real growthProgress: 1.0
    property real swayAmount: 0.0

    property int treeHeight: 12
    property int treeWidth: 11
    property int fontSize: 14
    property real taperRatio: 0.88

    property color trunkColor: Colours.palette.m3tertiary
    property color needleColorDark: Colours.palette.m3primary
    property color needleColorLight: Colours.palette.m3secondary
    property color needleColorHighlight: Colours.palette.m3primaryContainer
    property color coneColor: Colours.palette.m3tertiaryContainer

    property var treeData: []
    property bool ready: false

    Component.onCompleted: Qt.callLater(function() {
        generateTree()
        ready = true
    })
    onSeedChanged: if (ready) generateTree()
    onTreeHeightChanged: if (ready) generateTree()
    onTreeWidthChanged: if (ready) generateTree()
    onTaperRatioChanged: if (ready) generateTree()

    function randomFromSeed(index) {
        const x = Math.sin(seed + index * 127.1) * 10000
        return x - Math.floor(x)
    }

    // A wind-pruned leader leans above alternating, unequal shelves of needles.
    function generateTree() {
        const rows = []
        const width = Math.max(1, treeWidth)
        const height = Math.max(1, treeHeight)
        const foot = Math.floor((width - 1) / 2)
        const crown = Math.max(1, height - (height < 6 ? 1 : 2))
        const wind = randomFromSeed(3) < 0.5 ? -1 : 1
        const radius = Math.min((width - 1) / 2, crown * 0.65)
        const lean = Math.min(3, foot, Math.round(radius * (0.2 + randomFromSeed(4) * 0.25)))
        const phase = Math.floor(randomFromSeed(5) * 3)
        const taper = Math.max(0.2, taperRatio)

        for (let row = 0; row < height; ++row) {
            const chars = []
            const add = (x, char, ink) => chars.push({ x, char, ink })
            if (row >= crown) {
                if (row === height - 1 && width >= 3 && height >= 6) {
                    add(foot - 1, '⢀', 'bark')
                    add(foot, '┴', 'bark')
                    add(foot + 1, '⡀', 'bark')
                } else add(foot, '│', 'bark')
            } else {
                const t = row / Math.max(1, crown - 1)
                const spine = foot + wind * Math.round(lean * (1 - t) * (1 - t))
                // A slender leader gives way to broken, interlaced branch fans.
                const reach = radius * Math.pow(t, taper + 0.18)
                const span = side => {
                    const lee = side === wind
                    const shelf = (row + phase + (lee ? 0 : 2)) % 5
                    if (shelf === 0) return 0 // daylight all the way to the stem
                    const fan = shelf === 2 ? 1.18 : shelf === 3 ? 0.85 : 0.47
                    const length = 0.86 + randomFromSeed(190 + row * 2 + side) * 0.28
                    return Math.round(reach * (lee ? 1.08 : 0.88) * fan * length)
                }
                const left = Math.min(spine, span(-1))
                const right = Math.min(width - 1 - spine, span(1))
                for (let x = spine - left; x <= spine + right; ++x) {
                    const dx = x - spine
                    if (dx === 0) {
                        if (!row) add(x, '╷', 'light')
                        else if (!left || !right) add(x, '│', 'bark')
                        else if ((row + phase) % 3 === 0) add(x, '┿', 'bark')
                        else add(x, wind > 0 ? '⣷' : '⣾', 'needle')
                        continue
                    }
                    const tip = (dx < 0 ? left : right) - Math.abs(dx)
                    const n = randomFromSeed(row * 41 + x + 13)
                    let ch
                    if (tip === 0 && Math.abs(dx) >= 3 && n < 0.7) ch = dx < 0 ? '⡄' : '⢠'
                    else if (tip === 0) ch = dx < 0 ? (n < 0.5 ? '⢀' : '⣀') : (n < 0.5 ? '⡀' : '⣀')
                    else if (tip === 1) ch = dx < 0 ? (n < 0.4 ? '⢠' : '⣠') : (n < 0.4 ? '⡄' : '⣄')
                    else ch = dx < 0 ? (n < 0.55 ? '⣴' : '⣤') : (n < 0.55 ? '⣦' : '⣤')
                    add(x, ch, tip === 0 || (dx * wind > 0 && n < 0.4) ? 'light' : 'needle')
                }
            }
            rows.push({ row, chars })
        }
        treeData = rows
    }

    Column {
        id: crownColumn
        anchors.centerIn: parent
        spacing: -1
        // The 80 px session button uses the same eight rows as the larger panels.
        scale: Math.min(1, root.width > 0 && width > 0 ? root.width / width : 1,
                           root.height > 0 && height > 0 ? root.height / height : 1)

        Repeater {
            model: root.ready ? root.treeData : []
            delegate: Item {
                id: tier
                required property var modelData
                required property int index

                width: root.treeWidth * charMetrics.width
                height: charMetrics.height
                opacity: root.animated ? (index / root.treeData.length <= root.growthProgress ? 1 : 0) : 1
                Behavior on opacity { NumberAnimation { duration: 80 } }
                // Sway the whole bough, not each needle. Keep the foot planted.
                transform: Translate {
                    x: root.swayAmount * Math.pow(1 - tier.index / Math.max(1, root.treeHeight - 1), 2)
                }
                Repeater {
                    model: tier.modelData.chars
                    delegate: Text {
                        required property var modelData
                        x: modelData.x * charMetrics.width
                        text: modelData.char
                        color: modelData.ink === 'bark' ? root.trunkColor
                             : modelData.ink === 'light' ? root.needleColorLight : root.needleColorDark
                        font.family: Config.appearance.font.family.mono
                        font.pixelSize: root.fontSize
                        font.weight: Font.Normal
                    }
                }
            }
        }
    }

    TextMetrics {
        id: charMetrics
        font.family: Config.appearance.font.family.mono
        font.pixelSize: root.fontSize
        text: "█"
    }

    SequentialAnimation {
        id: growthAnimation
        paused: running && (!root.active || !root.visible)
        running: root.animated && root.growthProgress < 1
        loops: 1
        NumberAnimation {
            target: root
            property: "growthProgress"
            from: 0
            to: 1
            duration: 2500
            easing.type: Easing.OutCubic
        }
    }

    SequentialAnimation {
        paused: running && (!root.active || !root.visible)
        running: root.animated
        loops: Animation.Infinite
        NumberAnimation {
            target: root
            property: "swayAmount"
            from: -1.5
            to: 1.5
            duration: 4000
            easing.type: Easing.InOutSine
        }
        NumberAnimation {
            target: root
            property: "swayAmount"
            from: 1.5
            to: -1.5
            duration: 4000
            easing.type: Easing.InOutSine
        }
    }

    function regenerate() {
        const next = Math.floor(Math.random() * 10000)
        seed = next === seed ? (next + 1) % 10000 : next
    }

    function startGrowth() {
        growthProgress = 0
        growthAnimation.start()
    }
}
