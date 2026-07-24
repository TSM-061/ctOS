pragma Singleton

import QtQuick
import Quickshell

import qs.common
import qs.greeter.config
import qs.greeter.services

Singleton {
    id: terminalManager

    signal paused(string pauseMarker)

    // actual model for output messages
    property var logModel: ListModel {}

    // buffer for storing messages generated before terminal is ready
    property list<var> _queue: []

    // slot for an item that should be delivered on the next timer tick
    property var _pendingMsg: null

    // pausing prevents new output from being added
    property bool isPaused: false

    // locking means an input prompt won't be added
    readonly property bool locked: false

    enum MessageType {
        Output,
        Prompt
    }

    /*
        Output is ready to receive messages added to model.
    */
    function notifyReady() {
        // kick off processing when terminal becomes ready
        terminalManager.processQueue();
    }

    function createMessage(properties) {
        const instant = properties.instant || false;

        if (instant && (properties.pauseWithMarker || properties.unlock)) {
            throw new Error("TerminalManager.createMessage: 'instant' is incompatible with other message flags");
        }

        const message = {
            /* Actual message content. */
            message: properties.message || "",
            /* Message Type. */
            type: properties.type || TerminalManager.MessageType.Output,
            /* Should message be output immediately. */
            instant: instant,
            /* Allows terminal to sync with external events. */
            pauseWithMarker: properties.pauseWithMarker || "",
            syntheticCommand: properties.syntheticCommand || ""
        };

        return message;
    }

    function addToModel(items) {
        logModel.append(items);
        if (logModel.count > 50) {
            logModel.remove(0, logModel.count - 50);
        }
    }

    function displayMessages(messages: var) {
        if (!Array.isArray(messages)) {
            throw new Error("TerminalManager.displayMessages requires an array of message objects");
        }

        const items = messages.map(msg => createMessage(msg));

        terminalManager._queue.push(...items);

        processQueue();
    }

    function resume() {
        isPaused = false;
        processQueue();
    }

    function processQueue() {
        if (queueWorker.running) {
            return;
        }

        if (_pendingMsg) {
            const msg = _pendingMsg;
            _pendingMsg = null;

            addToModel(msg);

            if (msg.pauseWithMarker) {
                queueWorker.stop();
                paused(msg.pauseWithMarker);
                return;
            }

            if (msg.type === TerminalManager.MessageType.Prompt) {
                queueWorker.stop();
                return;
            }
        }

        let instantBatchProcessed = false;

        if (_queue[0]?.instant) {
            const instantMsgs = [];

            while (terminalManager._queue[0]?.instant) {
                instantMsgs.push(terminalManager._queue.shift());
            }

            addToModel(instantMsgs);

            instantBatchProcessed = true;
        }

        if (_queue.length === 0) {
            queueWorker.stop();

            if (!terminalManager.locked) {
                const prompt = createMessage({
                    type: TerminalManager.MessageType.Prompt,
                    instant: instantBatchProcessed
                });

                if (instantBatchProcessed) {
                    addToModel(prompt);
                } else {
                    _queue.push(prompt);
                    queueWorker.start();
                }
            }

            return;
        }

        // Add a natural random delay with messages being added to terminal

        const minDelay = 200;
        const maxDelay = 400;
        const delay = Math.random() * maxDelay;

        _pendingMsg = _queue.shift();

        queueWorker.interval = Utils.clamp(delay, minDelay, maxDelay);
        queueWorker.start();
    }

    Timer {
        id: queueWorker
        interval: 100

        onTriggered: terminalManager.processQueue()
    }

    readonly property string _blumePrefix: "[BLUME_IDP]"
    readonly property string _sentinelPrefix: "[SENTINEL]"

    Component.onCompleted: {
        const protocol = Settings.isTest ? "CTOS_TEST" : Settings.isGreetd || Settings.isKiosk ? "CTOS_GREETD" : Settings.isLockd ? "CTOS_LOCKD" : "CTOS_DEFAULT";
        displayMessages([
            {
                message: "REGION_LINK_ESTABLISHED : AU-SOUTH-EAST-2"
            },
            {
                message: "LOG_STREAM_CONNECTED // 1B7C5296-469D-4595-AD5D-4E31349CF13F"
            },
            {
                message: `WL_OUTPUT_FOUND: ${Settings.monitor} <-> ADDR_PTR: 0x${Faker.randomHexString()}`
            },
            {
                message: "---GREETER_UI_INITIALIZING---",
                pauseWithMarker: "UI_INIT"
            },
            {
                message: `◈ ${terminalManager._blumePrefix} using Protocol::${protocol}`
            },
            {
                message: `${terminalManager._blumePrefix} Authentication Session opened.`
            }
        ]);
    }

    Connections {
        target: AuthManager

        function onStateChanged() {
            switch (AuthManager.state) {
            case AuthManager.State.Loading:
                terminalManager.logModel.setProperty(terminalManager.logModel.count - 1, "syntheticCommand", "login");
                break;
            case AuthManager.State.Success:
                terminalManager.displayMessages([
                    {
                        message: `${terminalManager._blumePrefix} IDENTITY_VERIFIED // SID:${Faker.randomHexString(24)}`
                    },
                    {
                        message: `${terminalManager._blumePrefix} Authentication session closed.`
                    }
                ]);
                break;
            case AuthManager.State.Failed:
                terminalManager.displayMessages([
                    {
                        message: `${terminalManager._sentinelPrefix} Authentication Failed (TraceId: ${Faker.randomHexString(16)})`,
                        virtualCommand: "login"
                    },
                ], {
                    isCommandOutput: true
                });
                break;
            }
        }
    }
}
