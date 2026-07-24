pragma Singleton

import Quickshell
import QtQuick

import qs.greeter.config
import qs.common
import qs.greeter.services

Singleton {
    id: authManager

    Logger {
        id: logger
        name: "AuthManager"
    }

    enum State {
        // waiting for handler to be ready
        Inactive,

        // main states
        Ready,
        Loading,
        Failed,
        Success,

        // quit and grant access
        Finish
    }

    property int state: AuthManager.State.Inactive

    property string _username: SessionManager.activeUser?.username || ""

    property var _handler

    Component.onCompleted: {
        if (Settings.isTest) {
            _handler = FakeHandler;
        } else if (Settings.isGreetd || Settings.isKiosk) {
            _handler = GreetdHandler;
        } else if (Settings.isLockd) {
            _handler = LockdHandler;
        } else {
            throw new Error("No Auth Manager provided: set CTOS_MODE to 'greetd' or 'lockd'");
        }

        _handler.ready.connect(onReady);
        _handler.success.connect(onSuccess);
        _handler.failed.connect(onFailed);

        _handler.start();
    }

    function onReady() {
        authManager.state = AuthManager.State.Ready;
    }

    function onSuccess() {
        if (authManager.state !== AuthManager.State.Loading && authManager.state !== AuthManager.State.Ready) {
            logger.critical("Invalid state transition: manager not ready");
        }

        authManager.state = AuthManager.State.Success;
    }

    function onFailed() {
        if (authManager.state !== AuthManager.State.Loading && authManager.state !== AuthManager.State.Ready) {
            logger.critical("Invalid state transition: manager not ready");
        }

        authManager.state = AuthManager.State.Failed;

        resetTimer.start();
    }

    Timer {
        id: resetTimer
        interval: 500
        onTriggered: {
            authManager._handler.start();
        }
    }

    function respond(password: string) {
        if (authManager.state !== AuthManager.State.Ready) {
            logger.error("Invalid call: manager not ready");
            return;
        }

        authManager.state = AuthManager.State.Loading;

        loadTimer.password = password;
        loadTimer.start();
    }

    Timer {
        id: loadTimer
        interval: 1000
        property string password: ""
        onTriggered: {
            authManager._handler.respond(loadTimer.password);
        }
    }

    function finish() {
        authManager.state = AuthManager.State.Finish;
        authManager._handler.finish();
    }
}
