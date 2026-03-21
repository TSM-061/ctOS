pragma Singleton

import QtQuick
import Quickshell

import qs.common
import qs.greeter.services

Singleton {
    id: handler

    signal ready
    signal success
    signal failed

    Logger {
        id: logger
        name: "Faker"
    }

    Connections {
        target: SessionManager

        function onActiveUserChanged() {
            logger.info(`Active user changed, recreating fake session.`);
            sessionStarter.restart();
        }
    }

    function start() {
        sessionStarter.restart();
    }

    Timer {
        id: sessionStarter
        interval: 200
        repeat: true

        onTriggered: {
            handler.ready();
            sessionStarter.stop();
        }
    }

    function respond(password: string) {
        if (password === "password") {
            handler.success();
            logger.info("// AUTH SUCCESS");
        } else {
            handler.failed();
            logger.info("// AUTH ERROR");
        }
    }

    function finish() {
        Qt.quit();
    }
}
