pragma Singleton

import QtQuick
import Quickshell
import qs.greeter.services

Singleton {
    id: commandManager

    readonly property int maxHistory: 15
    property var _history: []
    property int _historyIndex: -1

    function sendCommand(input: string) {
        const raw = input.trim();
        if (!raw) {
            return;
        }

        if (_history[0] !== raw)
            _history.unshift(raw);
        if (_history.length > maxHistory)
            _history.pop();
        _historyIndex = -1;

        const [command, ...args] = raw.split(/\s+/);

        switch (command.toLowerCase()) {
        case "change":
            _handleChange(args);
            break;
        case "chusr":
            _handleUserChange(args.join(" "));
            break;
        case "chdesk":
            _handleDesktopChange(args.join(" "));
            break;
        case "list":
            _handleList(args);
            break;
        case "help":
            _showHelp();
            break;
        default:
            _err(`unknown command '${command}'`);
        }
    }

    // Returns the next older history entry (Up arrow)
    function previousHistory(): string {
        if (_history.length === 0)
            return "";
        _historyIndex = Math.min(_historyIndex + 1, _history.length - 1);
        return _history[_historyIndex];
    }

    // Returns the next newer history entry, or "" when past the newest (Down arrow)
    function nextHistory(): string {
        if (_historyIndex <= 0) {
            _historyIndex = -1;
            return "";
        }
        _historyIndex--;
        return _history[_historyIndex];
    }

    function _handleChange(args) {
        const noun = args[0]?.toLowerCase();
        const value = args.slice(1).join(" ");

        if (!noun || !value)
            return _err("usage: change <user|desktop> <new_value>");

        switch (noun) {
        case "user":
            _handleUserChange(value);
            break;
        case "desktop":
        case "desk":
            _handleDesktopChange(value);
            break;
        default:
            _err(`unknown target '${noun}'`);
        }
    }

    function _handleUserChange(value: string): void {
        if (!value)
            return _err("username or index required");

        if (SessionManager.setUser(value))
            _out(`user -> ${SessionManager.activeUser.username}`);
        else
            _err(`user '${value}' not found`);
    }

    function _handleDesktopChange(value: string): void {
        if (!value)
            return _err("desktop name or index required");

        if (SessionManager.setDesktop(value))
            _out(`desktop -> ${SessionManager.activeDesktop.name}`);
        else
            _err(`desktop '${value}' not found`);
    }

    function _handleList(args) {
        const noun = args[0]?.toLowerCase();
        switch (noun) {
        case "users":
            {
                const messages = SessionManager.users.map((u, i) => ({
                            message: `${i + 1}. ${u.username}`,
                            instant: true
                        }));
                TerminalManager.displayMessages(messages, {
                    isCommandOutput: true
                });
                break;
            }
        case "desktops":
        case "desk":
            {
                const messages = SessionManager.desktops.map((s, i) => ({
                            message: `${i + 1}. ${s.name}`,
                            instant: true
                        }));
                TerminalManager.displayMessages(messages, {
                    isCommandOutput: true
                });
                break;
            }
        default:
            _err("usage: list <users|desktops>");
        }
    }

    function _showHelp() {
        _out("commands: change, chusr, chdesk, list, help");
    }

    function _out(msg: string, prefix = "") {
        const line = prefix ? `${prefix} ${msg}` : msg;

        TerminalManager.displayMessages([
            {
                message: line,
                instant: true
            }
        ], {
            isCommandOutput: true
        });
    }

    function _err(msg: string, prefix = "ERR") {
        _out(`${msg}`, prefix);
    }
}
