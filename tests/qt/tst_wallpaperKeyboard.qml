import QtQuick
import QtTest
import "doubles"

TestCase {
    id: testCase
    name: "WallpaperKeyboard"
    when: windowShown
    visible: true
    width: 500
    height: 380

    Item { id: before; activeFocusOnTab: true }
    BackgroundPane { id: pane }
    Item { id: after; activeFocusOnTab: true }

    function focusedTile(entry) {
        const item = testCase.Window.window.activeFocusItem;
        compare(item.Accessible.role, Accessible.Button);
        verify(item.Accessible.name.includes(entry.relativePath), "focus names the wallpaper");
        const top = item.mapToItem(pane, 0, 0).y;
        verify(top >= 0 && top + item.height <= pane.height, "focused tile is visible without scrolling by hand");
        tryVerify(() => {
            const image = grabImage(pane);
            const x = Math.floor(item.mapToItem(pane, item.width / 2, 0).x);
            return image.pixel(x, top + 3).toString() === "#000000" && image.pixel(x, top + 5).toString() === "#ffffff";
        }, 1000, "a two-tone focus ring is painted over the thumbnail");
        return item;
    }

    function test_traverseAndSelect() {
        testCase.Window.window.width = width;
        testCase.Window.window.height = height;
        const first = pane.defaultWallpapersModel.entries[0];
        const second = Wallpapers.list[0];
        before.forceActiveFocus();
        keyClick(Qt.Key_Tab);
        const defaultTile = focusedTile(first);
        compare(Wallpapers.calls, 0);
        keyClick(Qt.Key_Return);
        compare(Wallpapers.last, first.path);
        compare(Wallpapers.calls, 1);
        keyClick(Qt.Key_Tab);
        const userTile = focusedTile(second);
        compare(Wallpapers.calls, 1);
        keyClick(Qt.Key_Space);
        compare(Wallpapers.last, second.path);
        compare(Wallpapers.calls, 2);
        keyClick(Qt.Key_Tab);
        verify(after.activeFocus);
        keyClick(Qt.Key_Backtab, Qt.ShiftModifier);
        verify(userTile.activeFocus);
        keyClick(Qt.Key_Backtab, Qt.ShiftModifier);
        verify(defaultTile.activeFocus);
        defaultTile.Accessible.pressAction();
        compare(Wallpapers.last, first.path);
        compare(Wallpapers.calls, 3);
        keyClick(Qt.Key_Backtab, Qt.ShiftModifier);
        verify(before.activeFocus);
        keyClick(Qt.Key_Tab);
        keyClick(Qt.Key_Tab);
        keyClick(Qt.Key_Enter);
        compare(Wallpapers.last, second.path);
        compare(Wallpapers.calls, 4);
        keyClick(Qt.Key_Backtab, Qt.ShiftModifier);
        mouseClick(defaultTile);
        compare(Wallpapers.last, first.path);
        compare(Wallpapers.calls, 5);
    }
}
