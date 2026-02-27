pragma Singleton

import Quickshell
import Quickshell.Io
import QtQuick

Singleton {
    id: userService

    property var users: []

    Process {
        id: usersProcess
        command: ["sh", "-c", "cat /etc/passwd"]
        running: true

        stdout: SplitParser {
            onRead: data => {
                if (!data) {
                    return;
                }

                const line = data.trim();

                if (line.length === 0) {
                    return;
                }

                const parts = line.split(':');
                if (parts.length < 7) {
                    return;
                }

                const username = parts[0];
                const uid = parseInt(parts[2], 10);
                const shell = parts[6];

                const isStandardRange = uid >= 1000 && uid < 60000;
                const hasValidShell = !shell.includes("nologin") && !shell.includes("false") && !shell.includes("sync");
                const isNotNobody = username !== "nobody";

                const isRealUser = isStandardRange && hasValidShell && isNotNobody;

                if (!isRealUser) {
                    return;
                }

                userService.users.push({
                    "username": username,
                    "homeDir": parts[5],
                    "shell": shell,
                    "uid": uid
                });

                // can't detect change as reference is stable accross object edit
                userService.usersChanged();
            }
        }
    }
}
