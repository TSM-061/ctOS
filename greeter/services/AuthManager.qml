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

    property bool _firstSession: true

    readonly property string _blumePrefix: "[BLUME_IDP]"
    readonly property string _sentinelPrefix: "[SENTINEL ]"

    Component.onCompleted: {
        TerminalManager.registerService(authManager);

        if (Settings.isTest) {
            _handler = FakeHandler;

            TerminalManager.displayMessages([
                {
                    message: `◈ ${authManager._blumePrefix} using Protocol::CTOS_TEST`
                }
            ]);
        } else if (Settings.isGreetd || Settings.isKiosk) {
            _handler = GreetdHandler;

            TerminalManager.displayMessages([
                {
                    message: `◈ ${authManager._blumePrefix} using Protocol::CTOS_GREETD`
                }
            ]);
        } else if (Settings.isLockd) {
            _handler = LockdHandler;

            TerminalManager.displayMessages([
                {
                    message: `◈ ${authManager._blumePrefix} using Protocol::CTOS_LOCKD`
                }
            ]);
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

        if (authManager._firstSession) {
            TerminalManager.displayMessages([
                {
                    message: `${authManager._blumePrefix} Opened session for User${authManager._username})`,
                    unlock: authManager
                }
            ]);
            authManager._firstSession = false;
        } else {
            TerminalManager.displayMessages([
                {
                    message: `${authManager._blumePrefix} Session recreated with existing parameters.`,
                    unlock: authManager
                }
            ]);
        }
    }

    function onSuccess() {
        if (authManager.state !== AuthManager.State.Loading && authManager.state !== AuthManager.State.Ready) {
            logger.critical("Invalid state transition: manager not ready");
        }

        authManager.state = AuthManager.State.Success;

        TerminalManager.displayMessages([
            {
                message: `${authManager._blumePrefix} IDENTITY_VERIFIED // SID:${Faker.randomHexString(24)}`,
                virtualCommand: "login"
            },
            {
                message: `${authManager._blumePrefix} Authentication session closed.`
            }
        ]);
    }

    function onFailed() {
        if (authManager.state !== AuthManager.State.Loading && authManager.state !== AuthManager.State.Ready) {
            logger.critical("Invalid state transition: manager not ready");
        }

        authManager.state = AuthManager.State.Failed;

        resetTimer.start();

        TerminalManager.displayMessages([
            {
                message: `${authManager._sentinelPrefix} Authentication Failed (TraceId: ${Faker.randomHexString(16)})`,
                virtualCommand: "login",
                lock: authManager
            },
        ], {
            isCommandOutput: true
        });
        // TODO fix race condition from session creation message and new command prompt
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
