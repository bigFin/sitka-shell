/*
 * SitkaTree - Procedural ASCII Sitka Spruce Tree
 * 
 * A beautiful procedural ASCII art representation of a Sitka Spruce tree
 * using braille characters and unicode symbols for fine detail.
 * 
 * Character palette:
 * - Sparse braille for foliage (light filtering through)
 * - Geometric box chars for trunk structure
 * - Triangular chars for branch tips and cones
 */

import QtQuick
import qs.components
import qs.services
import "../../config"

Item {
    id: root
    
    // Configuration
    property int seed: Math.floor(Math.random() * 10000)
    property bool animated: false
    property real growthProgress: 1.0
    property real swayAmount: 0.0
    
    // Tree shape parameters
    property int treeHeight: 12  // Shorter for better proportions
    property int treeWidth: 11   // Narrower for better cone shape
    property int fontSize: 14    // Larger for visibility
    property real taperRatio: 0.88
    
    // Colors from theme
    property color trunkColor: Colours.palette.m3tertiary
    property color needleColorDark: Colours.palette.m3primary
    property color needleColorLight: Colours.palette.m3secondary
    property color needleColorHighlight: Colours.palette.m3primaryContainer
    property color coneColor: Colours.palette.m3tertiaryContainer
    
    // Internal
    property var treeData: []
    property bool ready: false
    
    // ===== SIMPLIFIED CHARACTER SETS =====

    // Sparse braille (edges, light filtering through)
    readonly property var brailleSparse: [
        '⠁', '⠂', '⠃', '⠄', '⠅', '⠆', '⠇', '⠈', '⠉', '⠊', '⠋', '⠌', '⠍', '⠎', '⠏',
        '⠐', '⠑', '⠒', '⠓', '⠔', '⠕', '⠖', '⠗', '⠘', '⠙', '⠚', '⠛', '⠜', '⠝', '⠞', '⠟'
    ]

    // Dense braille (core foliage mass)
    readonly property var brailleDense: [
        '⣀', '⣁', '⣂', '⣃', '⣄', '⣅', '⣆', '⣇', '⣈', '⣉', '⣊', '⣋', '⣌', '⣍', '⣎', '⣏',
        '⣐', '⣑', '⣒', '⣓', '⣔', '⣕', '⣖', '⣗', '⣘', '⣙', '⣚', '⣛'
    ]

    // Trunk (unified abstract mix)
    readonly property var trunkChars: ['║', '┃', '│', '╬', '╫', '╪', '╔', '╗', '╚', '╝', '╠', '╣', '╦', '╩']

    // Twigs (branch structure)
    readonly property var twigChars: ['┋', '┊', '╌', '╍', '┄', '┅', '┆', '┇', '╲', '╱']
    
    Component.onCompleted: {
        // Delay initial generation to ensure charMetrics is ready
        Qt.callLater(function() {
            generateTree()
            ready = true
        })
    }
    
    onSeedChanged: generateTree()
    onTreeHeightChanged: generateTree()
    onTreeWidthChanged: generateTree()
    
    // Seeded random number generator
    function seededRandom(s) {
        const x = Math.sin(s) * 10000
        return x - Math.floor(x)
    }
    
    function randomFromSeed(index) {
        return seededRandom(seed + index * 127.1)
    }
    
    function pickRandom(arr, index) {
        return arr[Math.floor(randomFromSeed(index) * arr.length)]
    }
    
    function generateTree() {
        const newTree = []
        let charIndex = 0
        const centerX = Math.floor(treeWidth / 2)
        
        // ===== GENERATE CONIFER LAYERS (SIMPLE LINEAR CONE) =====
        const foliageEnd = treeHeight - 3
        
        for (let row = 0; row < foliageEnd; row++) {
            const rowChars = []
            const layerProgress = row / (foliageEnd - 1)
            
            // Simple linear cone - widens from top to bottom
            let widthAtRow = Math.floor(2 + (treeWidth - 4) * layerProgress)
            
            // Reduced width variation for smooth cone
            const widthVariation = (randomFromSeed(row * 13.7) - 0.5) * 1.5
            widthAtRow = Math.max(1, widthAtRow + widthVariation)
            
            // Whorl structure - creates stepped silhouette
            const isWhorl = (row % 5 === 0)  // Every 5th row extends slightly
            const whorlBonus = isWhorl ? 1 : 0
            
            widthAtRow = Math.max(1, widthAtRow + whorlBonus)
            const halfWidth = Math.floor(widthAtRow / 2)
            
            for (let col = -halfWidth; col <= halfWidth; col++) {
                const x = centerX + col
                const distFromCenter = Math.abs(col)
                const edgeDistance = halfWidth - distFromCenter
                const rand = randomFromSeed(charIndex++)
                
                let ch, color
                
                // Organic chunky gaps (create discontinuous patches) - more sparse (65% density)
                const chunkSeed = Math.floor(row / 3) * 100 + Math.floor(col / 2)
                const isInChunk = randomFromSeed(chunkSeed) > 0.35
                if (!isInChunk) continue
                
                // ===== TRUNK/BRANCH GEOMETRY scattered throughout (~25% chance) =====
                if (rand > 0.75 && edgeDistance > 1) {
                    ch = pickRandom(trunkChars, charIndex++)
                    color = Qt.darker(trunkColor, 1.0 + rand * 0.15)
                }
                // ===== EDGES - sparse braille with ragged gaps =====
                else if (edgeDistance <= 1) {
                    const skipEdge = randomFromSeed(row * 7.3 + col) > 0.55
                    if (skipEdge) continue
                    ch = pickRandom(brailleSparse, charIndex++)
                    color = Qt.lighter(needleColorLight, 1.1 + rand * 0.2)
                }
                // ===== TWIG hints (occasional) =====
                else if (rand > 0.88 && edgeDistance > 2) {
                    ch = pickRandom(twigChars, charIndex++)
                    color = Qt.darker(trunkColor, 1.0 + rand * 0.2)
                }
                // ===== CORE FOLIAGE - dense braille =====
                else {
                    ch = pickRandom(brailleDense, charIndex++)
                    color = Qt.darker(needleColorDark, 1.0 + rand * 0.15)
                }
                
                // Final organic gap check
                const skipThreshold = edgeDistance <= 1 ? 0.2 : (edgeDistance <= 3 ? 0.12 : 0.06)
                if (rand > skipThreshold) {
                    rowChars.push({ char: ch, color: color, x: x })
                }
            }
            

            
            newTree.push({ row: row, chars: rowChars })
        }
        
        // ===== TRUNK (bottom section) =====
        for (let row = foliageEnd; row < treeHeight; row++) {
            const rowChars = []
            const trunkRow = row - foliageEnd
            const trunkWidth = trunkRow === 0 ? 3 : (trunkRow === 1 ? 4 : 5)
            const halfTrunk = Math.floor(trunkWidth / 2)
            
            for (let col = -halfTrunk; col <= halfTrunk; col++) {
                const x = centerX + col
                const rand = randomFromSeed(charIndex++)
                let ch, color
                
                // Random pick from unified trunkChars pool for ALL trunk positions
                ch = pickRandom(trunkChars, charIndex++)
                color = Qt.darker(trunkColor, 1.0 + rand * 0.2)
                
                rowChars.push({ char: ch, color: color, x: x })
            }
            
            newTree.push({ row: row, chars: rowChars })
        }
        
        treeData = newTree
    }
    
    // Render the tree
    Column {
        anchors.centerIn: parent
        spacing: -1
        
        Repeater {
            model: root.ready ? root.treeData : []
            
            delegate: Item {
                required property var modelData
                required property int index
                
                width: root.treeWidth * charMetrics.width
                height: charMetrics.height
                
                opacity: root.animated ? (index / root.treeData.length <= root.growthProgress ? 1 : 0) : 1
                
                Behavior on opacity {
                    NumberAnimation { duration: 80 }
                }
                
                Repeater {
                    model: modelData.chars
                    
                    delegate: Text {
                        required property var modelData
                        
                        // Fix centering by using proper offset from left edge
                        x: (modelData.x * charMetrics.width) + (root.swayAmount * Math.sin(index * 0.3) * (index / root.treeHeight))
                        
                        text: modelData.char
                        color: modelData.color
                        font.family: Config.appearance.font.family.mono
                        font.pixelSize: root.fontSize
                        font.weight: Font.Normal
                        
                        Behavior on x {
                            NumberAnimation { duration: 400; easing.type: Easing.InOutSine }
                        }
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
        id: swayAnimation
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
        seed = Math.floor(Math.random() * 10000)
    }
    
    function startGrowth() {
        growthProgress = 0
        growthAnimation.start()
    }
}