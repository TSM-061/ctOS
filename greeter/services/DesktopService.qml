pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.greeter.config

Singleton {
    id: desktopService

    property var sessions: []
    property var activeSession: null
    property var _currentSession: ({
            "_uwsmManaged": false
        })

    property bool _isUsingUwsm: false

    Process {
        id: uwsmProcess
        command: ["sh", "-c", "env | grep -q '^UWSM'"]
        running: true
        // qmllint disable signal-handler-parameters
        onExited: (exitCode, exitStatus) => {
            desktopService._isUsingUwsm = exitCode === 0;
            sessionsProcess.running = true;
        }
    }

    Process {
        id: sessionsProcess

        // print out all desktop entries line by line in one stream
        command: ["sh", "-c", "cat /usr/share/wayland-sessions/*.desktop 2>/dev/null"]
        running: false
        // qmllint disable signal-handler-parameters
        onExited: (exitCode, exitStatus) => {
            // need to handle the last processed entry since there's no more lines
            sessionsProcess.commitSession();
            const currentDesktop = (Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "").toLowerCase();

            let targetSession = desktopService.sessions.find(session => {
                const matchesUwsm = session._uwsmManaged === desktopService._isUsingUwsm;
                const matchesActive = currentDesktop && session.name && session.name.toLowerCase().includes(currentDesktop);
                return matchesUwsm && matchesActive;
            });

            if (!targetSession)
                targetSession = desktopService.sessions.find(session => {
                    return session.name.toLowerCase().includes(currentDesktop);
                });

            desktopService.activeSession = targetSession || (desktopService.sessions.length > 0 ? desktopService.sessions[0] : null);
        }

        stdout: SplitParser {
            onRead: data => {
                if (!data)
                    return;

                const line = data.trim();
                if (line.length === 0)
                    return;

                if (line === "[Desktop Entry]") {
                    // end of one entry
                    sessionsProcess.commitSession();
                    return;
                }
                const parts = line.split('=');
                if (parts.length < 2)
                    return;

                const [key, value] = parts;

                // qml might reserve pascal case object properties
                desktopService._currentSession[key.toLowerCase()[0] + key.slice(1, key.length)] = value;

                if (value.toLowerCase().includes("uwsm")) {
                    desktopService._currentSession._uwsmManaged = true;
                }
            }
        }

        function commitSession() {
            if (desktopService._currentSession && desktopService._currentSession.name) {
                desktopService.sessions.push(desktopService._currentSession);
                desktopService.sessionsChanged();
            }
            desktopService._currentSession = {
                "_uwsmManaged": false
            };
        }
    }
}
