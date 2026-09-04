import qs.utils
import Quickshell.Io

JsonObject {
    property string wallpaperDir: `${Paths.pictures}/Wallpapers`
    property string recordings: `${Paths.videos}/Recordings`
    property string sessionGif: "root:/config/Images/sitka-vfd-2.jpeg"
    property string mediaGif: "root:/config/Images/sitka-vfd-1.jpeg"
    // Optional directories whose images rotate through the session and
    // media decorations. Empty (default) keeps the single gif above.
    property string sessionGifDir: ""
    property string mediaGifDir: ""
    // Seconds between decoration swaps. Zero or negative disables cycling.
    property int decorationCycleSeconds: 0
}
