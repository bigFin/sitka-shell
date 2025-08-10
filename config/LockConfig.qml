import Quickshell.Io

JsonObject {
    property int maxNotifs: 5
    property Sizes sizes: Sizes {}

    component Sizes: JsonObject {
        property int centerWidth: 600
    }
}
