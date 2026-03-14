pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.common

Singleton {
    id: root

    Logger {
        id: logger
        name: "settings"
    }

    ConfigManager {
        id: globalManager
        path: Paths.globalConfigPath("greeter.config")

        adapter: JsonAdapter {
            id: globalAdapter
            property GeneralDto general: GeneralDto {}
        }
    }

    ConfigManager {
        id: stateManager
        path: Paths.statePath("greeter.state")
        writeEnabled: root.isGreetd

        adapter: JsonAdapter {
            id: stateAdapter
            property StateDto session: StateDto {}
        }
    }

    readonly property GeneralDto general: globalAdapter.general

    property string defaultUsername: stateAdapter.session.defaultUsername
    property string defaultDesktopName: stateAdapter.session.defaultDesktopName

    readonly property string modeKey: Object.keys(root.modes).find(key => root.modes[key] === root.mode)

    readonly property int mode: {
        const key = (Env.get("MODE") || "").toLowerCase();

        if (modes.hasOwnProperty(key)) {
            Env.log("MODE", key);
            return modes[key];
        }

        Env.log("MODE", "test", true);
        return modes.test;
    }

    readonly property bool isDebug: Env.get("DEBUG") === "1"
    readonly property bool isTest: mode === modes.test
    readonly property bool isGreetd: mode === modes.greetd
    readonly property bool isLockd: mode === modes.lockd
    readonly property bool isKiosk: mode === modes.kiosk

    readonly property string monitor: general.modes[modeKey].monitor || general.monitor || Quickshell.screens[0].name
    readonly property string fontFamily: general.fontFamily

    enum AnimationMode {
        None = 0,
        Reduced = 1,
        All = 2
    }

    readonly property int animationMode: {
        const value = (general.modes[modeKey].animations || general.animations || "").toLowerCase();

        switch (value) {
        case "none":
            return Settings.AnimationMode.None;
        case "reduced":
            return Settings.AnimationMode.Reduced;
        case "all":
            return Settings.AnimationMode.All;
        default:
            return Settings.AnimationMode.All;
        }
    }

    function animationProfile(mode: int): bool {
        return animationMode >= mode;
    }

    readonly property var launchCommand: general.launchOverride
    readonly property var exitCommand: general.exitOverride

    readonly property var modes: {
        "test": 0,
        "lockd": 1,
        "greetd": 2,
        "kiosk": 3
    }
}
