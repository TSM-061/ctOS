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
            _handleUserChange(args);
            break;
        case "chdesk":
            _handleDesktopChange(args);
            break;
        case "users":
            _handleListUsers();
            break;
        case "desktops":
        case "desk":
            _handleListDesktops();
            break;
        case "help":
            _showHelp();
            break;
        default:
            _err(`unknown command '${command}'`);
        }
    }

    function previousHistory(): string {
        if (_history.length === 0)
            return "";
        _historyIndex = Math.min(_historyIndex + 1, _history.length - 1);
        return _history[_historyIndex];
    }

    function nextHistory(): string {
        if (_historyIndex <= 0) {
            _historyIndex = -1;
            return "";
        }
        _historyIndex--;
        return _history[_historyIndex];
    }

    function _handleChange(args) {
        const subCommand = args[0]?.toLowerCase();
        const restArgs = args.slice(1);

        if (!subCommand)
            return _err("usage: change <user|desktop> [options] <value>");

        switch (subCommand) {
        case "user":
            _handleUserChange(restArgs);
            break;
        case "desktop":
        case "desk":
            _handleDesktopChange(restArgs);
            break;
        default:
            _err(`unknown target '${subCommand}'`);
        }
    }

    function _consumeFlags(args: list<string>, supportedFlags: var): var {
        const flags = {};
        const remaining = [];

        for (const arg of args) {
            if (arg in supportedFlags) {
                flags[arg] = true;
            } else {
                remaining.push(arg);
            }
        }

        return {
            flags,
            remaining
        };
    }

    function _handleUserChange(args: list<string>): void {
        const flagInfo = _consumeFlags(args, {
            "-d": true,
            "--default": true
        });

        if (!flagInfo)
            return;

        if (flagInfo.remaining.length !== 1) {
            return _err("expected exactly one argument (username or index)");
        }

        const value = flagInfo.remaining[0];
        const saveDefault = flagInfo.flags["-d"] || flagInfo.flags["--default"];

        if (SessionManager.setUser(value, saveDefault))
            _out(`user -> ${SessionManager.activeUser.username}${saveDefault ? ' [default]' : ''}`);
        else
            _err(`user '${value}' not found`);
    }

    function _handleDesktopChange(args: list<string>): void {
        const flagInfo = _consumeFlags(args, {
            "-d": true,
            "--default": true
        });

        if (!flagInfo)
            return;

        if (flagInfo.remaining.length !== 1) {
            return _err("expected exactly one argument (desktop name or index)");
        }

        const value = flagInfo.remaining[0];
        const saveDefault = flagInfo.flags["-d"] || flagInfo.flags["--default"];

        if (SessionManager.setDesktop(value, saveDefault))
            _out(`desktop -> ${SessionManager.activeDesktop.name}${saveDefault ? ' [default]' : ''}`);
        else
            _err(`desktop '${value}' not found`);
    }

    function _handleListUsers(): void {
        const messages = SessionManager.users.map((u, i) => ({
                    message: `${i + 1}. ${u.username.toUpperCase()} (${u.uid})`,
                    instant: true
                }));
        TerminalManager.displayMessages(messages, {
            isCommandOutput: true
        });
    }

    function _handleListDesktops(): void {
        const messages = SessionManager.desktops.map((s, i) => ({
                    message: `${i + 1}. ${s.name}`,
                    instant: true
                }));
        TerminalManager.displayMessages(messages, {
            isCommandOutput: true
        });
    }

    function _showHelp() {
        _out("commands: change, chusr, chdesk, users, desktops, help");
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
