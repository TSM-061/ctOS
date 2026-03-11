import QtQuick
import Quickshell.Io

JsonObject {
    property string animations: "all"
    property string fontFamily: "JetBrainsMono Nerd Font"
    property list<string> exitOverride: []
    property list<string> launchOverride: []
    property string monitor: ""

    component ModeSettings: JsonObject {
        property string animations: "all"
        property string monitor: ""
    }

    property JsonObject modes: JsonObject {
        property ModeSettings greetd: ModeSettings {}
        property ModeSettings lockd: ModeSettings {
            animations: "reduced"
        }
        property ModeSettings test: ModeSettings {}
    }
}
