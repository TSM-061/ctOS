import QtQuick
import Quickshell
import Quickshell.Io

JsonObject {
    id: root

    // TODO modify the install script to match these changes

    property string defaultUser: Quickshell.env("USER") || ""
    property string defaultDesktop: ""
    property string fontFamily: "JetBrainsMono Nerd Font"
    property string animations: "all"
    property string monitor: Quickshell.screens[0].name

    property list<string> exitOverride: []
    property list<string> launchOverride: []

    property FakeStatus fakeStatus: FakeStatus {}
    property Modes modes: Modes {}

    component FakeStatus: JsonObject {
        property string env: "WORKSTATION"
        property string node: "109.389.013.301"
    }

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
