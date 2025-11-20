import Quickshell.Io

JsonObject {
    property string theme: "EverforestDark"
    property Apps apps: Apps {}

    component Apps: JsonObject {
        property list<string> terminal: ["foot"]
        property list<string> audio: ["pavucontrol"]
    }
}
