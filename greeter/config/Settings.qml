pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.common
import qs.greeter.services

Singleton {
    id: root

    Logger {
        id: logger
        name: "settings"
    }

    property string modeKey: Object.keys(root.modes).find(key => root.modes[key] === root.mode)

    ConfigManager {
        id: cm
        fileName: "test"
        global: false

        adapter: JsonAdapter {
            property SettingsDto settings: SettingsDto {}
        }
    }

    readonly property SettingsDto dto: cm.adapter.settings // qmllint disable missing-property

    Connections {
        target: DesktopService
        function onActiveSessionChanged() {
            if (!root.dto.defaultDesktop) {
                root.dto.defaultDesktop = DesktopService.activeSession?.name || DesktopService.sessions[0].name;
            }
        }
    }

    readonly property string monitor: dto.modes[modeKey].monitor || dto.monitor
    readonly property string user: dto.defaultUser
    readonly property string fontFamily: dto.fontFamily

    readonly property var fakeStatus: ({
            "env": dto.fakeStatus.env,
            "node": dto.fakeStatus.node
        })

    enum AnimationMode {
        None = 0,
        Reduced = 1,
        All = 2
    }

    readonly property int animationMode: {
        const value = dto.modes[modeKey].animations.toLowerCase() || dto.animations.toLowerCase();

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

    function getCommand(overrideList, defaultList) {
        if (overrideList && overrideList.length > 0)
            return overrideList;
        return defaultList || [];
    }

    readonly property var launchCommand: getCommand(dto.launchOverride, dto.launchOverride)
    readonly property var exitCommand: getCommand(dto.exitOverride, dto.exitOverride)

    readonly property var modes: {
        "test": 0,
        "lockd": 1,
        "greetd": 2,
        "kiosk": 3
    }

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
}
