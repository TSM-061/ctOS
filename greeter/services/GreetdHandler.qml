pragma Singleton

import Quickshell
import Quickshell.Services.Greetd
import QtQuick

import qs.greeter.services
import qs.common

Singleton {
    id: handler

    signal ready
    signal success
    signal failed

    Logger {
        id: logger
        name: "Greetd"
    }

    Connections {
        id: connection
        target: Greetd

        function onAuthMessage(message) {
            // requesting password
            logger.info("Credentials requested.");
            handler.ready();
        }

        function onAuthFailure(message) {
            // password is wrong
            logger.info("Authentication failed.");
            handler.failed();
        }

        function onReadyToLaunch() {
            // password is correct
            logger.info("Authentication success.");
            handler.success();
        }
    }

    Connections {
        target: SessionManager

        function onActiveUserChanged() {
            if (Greetd.state === GreetdState.Authenticating) {
                logger.info(`User changed, cancelling active session.`);
                Greetd.cancelSession();
            }

            handler.start();
        }
    }

    function start() {
        sessionStarter.start();
    }

    Timer {
        id: sessionStarter
        interval: 200
        repeat: true
        onTriggered: {
            // make sure socket ready for new session
            // authenticating(1) -> inactive (0)
            if (Greetd.state !== GreetdState.Inactive) {
                return;
            }

            logger.info(`Created session (user:${SessionManager.activeUser.uid}:${SessionManager.activeUser.username})`);
            Greetd.createSession(SessionManager.activeUser.username);

            sessionStarter.stop();
        }
    }

    function respond(password) {
        if (Greetd.available) {
            Greetd.respond(password);
        } else {
            logger.debug("Failed to respond, Not available.");
        }
    }

    function finish() {
        const launchCommand = SessionManager.getLaunchCommand();
        const exitCommand = SessionManager.getExitCommand();

        logger.info(`Launching: ${launchCommand.join(" ")}`);
        logger.info(`Exiting Greeter: ${exitCommand.join(" ") || "<none>"}`);

        Greetd.launch(launchCommand);

        if (exitCommand.length) {
            Quickshell.execDetached(exitCommand);
        }
    }
}
