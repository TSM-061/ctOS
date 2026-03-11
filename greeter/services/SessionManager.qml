pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.greeter.config

Singleton {
    id: sessionManager

    property bool _isUsingUwsm: false

    property var users: []
    property string activeUser: Settings.defaultUser || sessionManager._foundUser
    property var _foundUser: null

    property var desktops: []
    property var activeDesktop: Settings.defaultDesktop || sessionManager._foundDesktop
    property var _foundDesktop: null

    property var _currentDesktopEntry: ({
            "_uwsmManaged": false
        })

    function _findIn(list, value: string, key: string) {
        const oneBasedIdx = parseInt(value);
        return !isNaN(oneBasedIdx) ? (list[oneBasedIdx - 1] ?? null) : (list.find(item => item[key].toLowerCase().includes(value.toLowerCase())) ?? null);
    }

    function setUser(value: string): bool {
        const found = sessionManager._findIn(sessionManager.users, value, "username");

        if (!found)
            return false;

        sessionManager.activeUser = found.username;
        return true;
    }

    function setDesktop(value: string): bool {
        const found = sessionManager._findIn(sessionManager.desktops, value, "name");

        if (!found)
            return false;

        sessionManager.activeDesktop = found;
        return true;
    }

    function getExitCommand() {
        if (Settings.exitCommand && Settings.exitCommand.length) {
            return Settings.exitCommand;
        }

        // Prefer uwsm when available
        if (sessionManager._isUsingUwsm) {
            return ["uwsm", "stop"];
        }

        const currentDesktop = (Quickshell.env("XDG_CURRENT_DESKTOP") || "").toLowerCase();

        if (currentDesktop.includes("hyprland")) {
            return ["hyprctl", "dispatch", "exit"];
        }

        if (currentDesktop.includes("niri")) {
            return ["niri", "msg", "action", "quit"];
        }

        return [];
    }

    function getLaunchCommand() {
        const desktop = sessionManager.activeDesktop;

        if (!desktop || !desktop.exec)
            return [];

        return desktop.exec.trim().split(" ");
    }

    Process {
        id: uwsmProcess
        command: ["sh", "-c", "env | grep -q '^UWSM'"]
        running: true

        // qmllint disable signal-handler-parameters
        onExited: exitCode => {
            sessionManager._isUsingUwsm = exitCode === 0;
            desktopsProcess.running = true;
        }
    }

    Process {
        id: usersProcess
        command: ["sh", "-c", "cat /etc/passwd"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (!data)
                    return;

                const line = data.trim();
                if (line.length === 0)
                    return;

                const parts = line.split(':');
                if (parts.length < 7)
                    return;

                const username = parts[0];
                const uid = parseInt(parts[2], 10);
                const shell = parts[6];

                const isStandardRange = uid >= 1000 && uid < 60000;
                const hasValidShell = !shell.includes("nologin") && !shell.includes("false") && !shell.includes("sync");
                const isNotNobody = username !== "nobody";

                if (!(isStandardRange && hasValidShell && isNotNobody))
                    return;

                sessionManager.users.push({
                    "username": username,
                    "homeDir": parts[5],
                    "shell": shell,
                    "uid": uid
                });
                sessionManager.usersChanged();

                sessionManager._foundUser = sessionManager.users[0].username;
            }
        }
    }

    Process {
        id: desktopsProcess
        command: ["sh", "-c", "cat /usr/share/wayland-sessions/*.desktop 2>/dev/null"]
        running: false
        // qmllint disable signal-handler-parameters
        onExited: (exitCode, exitStatus) => {
            desktopsProcess.commitDesktop();

            const currentDesktop = (Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "").toLowerCase();

            let targetDesktop = sessionManager.desktops.find(desktop => {
                const matchesUwsm = desktop._uwsmManaged === sessionManager._isUsingUwsm;
                const matchesActive = currentDesktop && desktop.name && desktop.name.toLowerCase().includes(currentDesktop);
                return matchesUwsm && matchesActive;
            });

            if (!targetDesktop) {
                targetDesktop = sessionManager.desktops.find(desktop => desktop.name.toLowerCase().includes(currentDesktop));
            }

            sessionManager._foundDesktop = targetDesktop || (sessionManager.desktops.length > 0 ? sessionManager.desktops[0] : null);
        }

        stdout: SplitParser {
            onRead: data => {
                if (!data)
                    return;

                const line = data.trim();
                if (line.length === 0)
                    return;

                if (line === "[Desktop Entry]") {
                    desktopsProcess.commitDesktop();
                    return;
                }

                const parts = line.split('=');
                if (parts.length < 2)
                    return;

                const [key, value] = parts;
                sessionManager._currentDesktopEntry[key.toLowerCase()[0] + key.slice(1)] = value;

                if (value.toLowerCase().includes("uwsm"))
                    sessionManager._currentDesktopEntry._uwsmManaged = true;
            }
        }

        function commitDesktop() {
            if (sessionManager._currentDesktopEntry && sessionManager._currentDesktopEntry.name) {
                sessionManager.desktops.push(sessionManager._currentDesktopEntry);
                sessionManager.desktopsChanged();
            }
            sessionManager._currentDesktopEntry = {
                "_uwsmManaged": false
            };
        }
    }
}
