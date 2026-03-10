import QtQuick
import Quickshell
import Quickshell.Io

JsonObject {
    id: root

    // TODO modify the install script to match these changes

    // property string defaultUser: ""
    // property string defaultDesktop: ""

    property string fontFamily: "JetBrainsMono Nerd Font"
    property string animations: "all"
    property string monitor: Quickshell.screens[0].name

    property var exitOverride: null
    property var launchOverride: null

    property Modes modes: Modes {}

    component ModeSettings: JsonObject {
        property string animations: "all"
        property string monitor: ""
    }

    component Modes: JsonObject {
        property ModeSettings greetd: ModeSettings {}

        property ModeSettings lockd: ModeSettings {
            animations: "reduced"
        }

        property ModeSettings test: ModeSettings {
            animations: "reduced"
        }
    }
}
