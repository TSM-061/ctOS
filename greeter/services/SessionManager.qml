pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.greeter.config
import qs.greeter.data

Singleton {
    id: sessionManager

    property bool _isUsingUwsm: false

    property list<User> users: []
    property list<Desktop> desktops: []

    property User activeUser: sessionManager.findUser(Settings.defaultUsername) || _firstUser
    property var _firstUser: null

    property Desktop activeDesktop: sessionManager.findDesktop(Settings.defaultDesktopName) || _firstDesktop
    property var _firstDesktop: null

    Component {
        id: userFactory
        User {}
    }

    Component {
        id: desktopFactory
        Desktop {}
    }

    function _findIn(list, value, key) {
        if (!value) {
            return null;
        }

        const oneBasedIdx = parseInt(value);
        if (!isNaN(oneBasedIdx)) {
            return list[oneBasedIdx - 1] ?? null;
        }

        return list.find(item => {
            const itemValue = item[key].toLowerCase();
            const searchValue = value.toLowerCase();
            return itemValue.includes(searchValue);
        }) ?? null;
    }

    function findUser(value) {
        return _findIn(users, value, "username");
    }

    function findDesktop(value) {
        return _findIn(desktops, value, "name");
    }

    function setUser(value, saveDefault = false) {
        const found = findUser(value);
        if (!found) {
            return false;
        }

        activeUser = found;

        if (saveDefault) {
            Settings.defaultUsername = found.username;
        }

        return true;
    }

    function setDesktop(value, saveDefault = false) {
        const found = findDesktop(value);
        if (!found) {
            return false;
        }

        activeDesktop = found;

        if (saveDefault) {
            Settings.defaultDesktopName = found.name;
        }

        return true;
    }

    function getExitCommand() {
        if (Settings.exitCommand && Settings.exitCommand.length) {
            return Settings.exitCommand;
        }

        if (_isUsingUwsm) {
            return ["uwsm", "stop"];
        }

        const xdg = Quickshell.env("XDG_CURRENT_DESKTOP") || "";
        const env = xdg.toLowerCase();

        if (env.includes("hyprland")) {
            return ["hyprctl", "dispatch", "exit"];
        }

        if (env.includes("niri")) {
            return ["niri", "msg", "action", "quit"];
        }

        return [];
    }

    function getLaunchCommand() {
        if (!activeDesktop || !activeDesktop.exec) {
            return [];
        }
        return activeDesktop.exec.trim().split(/\s+/);
    }

    Process {
        id: uwsmCheck
        command: ["sh", "-c", "env | grep -q '^UWSM'"]
        running: true
        onExited: exitCode => {
            _isUsingUwsm = (exitCode === 0);
            desktopsProcess.running = true;
        }
    }

    Process {
        id: usersProcess
        command: ["sh", "-c", "cat /etc/passwd"]
        running: true
        stdout: SplitParser {
            onRead: data => {
                const parts = data.trim().split(":");
                if (parts.length < 7) {
                    return;
                }

                const [user, , uidStr, , , home, shell] = parts;
                const uid = parseInt(uidStr);

                const isStandard = (uid >= 1000 && uid < 60000);
                const isRealUser = !shell.match(/nologin|false|sync/);
                const isNotNobody = (user !== "nobody");

                if (isStandard && isRealUser && isNotNobody) {
                    const userObj = userFactory.createObject(sessionManager, {
                        "username": user,
                        "homeDir": home,
                        "shell": shell,
                        "uid": uid
                    });

                    users.push(userObj);
                    usersChanged();

                    if (!_firstUser) {
                        _firstUser = userObj;
                    }
                }
            }
        }
    }

    Process {
        id: desktopsProcess
        property var _currentEntry: ({})

        command: ["sh", "-c", "cat /usr/share/wayland-sessions/*.desktop 2>/dev/null"]
        running: false

        stdout: SplitParser {
            onRead: data => {
                const line = data.trim();
                if (!line) {
                    return;
                }

                if (line === "[Desktop Entry]") {
                    desktopsProcess.commit();
                    return;
                }

                const splitIdx = line.indexOf("=");
                if (splitIdx === -1) {
                    return;
                }

                const [key, value] = line.split("=");

                switch (key) {
                case "Name":
                    desktopsProcess._currentEntry.name = value;
                    break;
                case "Comment":
                    desktopsProcess._currentEntry.comment = value;
                    break;
                case "Exec":
                    desktopsProcess._currentEntry.exec = value;
                    break;
                case "Type":
                    desktopsProcess._currentEntry.type = value;
                    break;
                case "DesktopNames":
                    desktopsProcess._currentEntry.desktopNames = value;
                    break;
                }

                if (value.toLowerCase().includes("uwsm")) {
                    desktopsProcess._currentEntry._uwsmManaged = true;
                }
            }
        }

        onExited: {
            desktopsProcess.commit();

            const xdg = Quickshell.env("XDG_CURRENT_DESKTOP") || "";
            const env = xdg.toLowerCase();

            const detectedDesktop = desktops.find(d => {
                const nameMatch = env && d.name.toLowerCase().includes(env);
                const uwsmMatch = (d._uwsmManaged === _isUsingUwsm);
                return nameMatch && uwsmMatch;
            });

            _firstDesktop = detectedDesktop || (desktops.length > 0 ? desktops[0] : null);
        }

        function commit() {
            const entry = desktopsProcess._currentEntry;

            if (entry.name && entry.exec) {
                const desktopObj = desktopFactory.createObject(sessionManager, entry);
                desktops.push(desktopObj);
                desktopsChanged();
            }

            desktopsProcess._currentEntry = {
                "_uwsmManaged": false
            };
        }
    }
}
