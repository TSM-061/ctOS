pragma Singleton

import QtQuick
import Quickshell

import qs.common
import qs.greeter.config
import qs.greeter.data

Singleton {
    id: terminalManager

    signal paused(string pauseMarker)

    property int state: TerminalManager.State.Booting

    // actual model for output messages
    property var logModel: ListModel {}

    // buffer for storing messages generated before terminal is ready
    property list<var> _queue: []

    // slot for an item that should be delivered on the next timer tick
    property var _pendingMsg: null

    // pausing prevents new output from being added
    property bool isPaused: false

    // locking means an input prompt won't be added
    property var _serviceLocks: []
    readonly property bool isLocked: _serviceLocks.some(service => service.locked)

    property bool isFirstPrompt: true

    enum State {
        Booting,
        Interactive,
        Busy,
        TearDown
    }

    enum MessageType {
        Output,
        Prompt
    }

    function registerService(service) {
        _serviceLocks.push({
            id: service.toString(),
            locked: true
        });

        _serviceLocksChanged();
    }

    function unlock(service) {
        const foundService = _serviceLocks.find(s => s.id === service.toString());

        if (!foundService) {
            throw new Error(`Service not registered: '${service}'`);
        }

        foundService.locked = false;
        _serviceLocksChanged();

        if (!isLocked && state === TerminalManager.State.Booting) {
            terminalManager.state = TerminalManager.State.Interactive;
        }
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
            pauseWithMarker: properties.pauseWithMarker || ""
        };

        if (properties.unlock) {
            // role is not created if member is null
            message.unlock = properties.unlock;
        }

        return message;
    }

    function createMessageOptions(properties) {
        return {
            /* Is output from a user command. */
            isCommandOutput: properties?.isCommandOutput || false
        };
    }

    function cleanLogModel() {
        if (logModel.count > 50) {
            logModel.remove(0, logModel.count - 50);
        }
    }

    function displayMessages(messages: var, options: var) {
        if (!Array.isArray(messages)) {
            throw new Error("TerminalManager.displayMessages requires an array of message objects");
        }

        options = options || {};

        const {
            isCommandOutput
        } = createMessageOptions(options);

        const items = messages.map(msg => createMessage(msg));

        if (isCommandOutput) {
            items.push(createMessage({
                type: TerminalManager.MessageType.Prompt,
                instant: true
            }));
        }

        terminalManager._queue.push(...items);

        processQueue();
    }

    function resume() {
        isPaused = false;
        processQueue();
    }

    Component.onCompleted: {
        registerService(terminalManager);

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
                pauseWithMarker: "UI_INIT",
                unlock: terminalManager
            }
        ]);
    }

    function processQueue() {
        if (worker.running) {
            return;
        }

        if (_pendingMsg) {
            const msg = _pendingMsg;
            _pendingMsg = null;

            logModel.append(msg);
            cleanLogModel();

            if (msg.unlock) {
                unlock(msg.unlock);
            }

            if (msg.pauseWithMarker) {
                worker.stop();
                paused(msg.pauseWithMarker);
                return;
            }
        }

        if (_queue.length === 0) {
            worker.stop();

            if (isFirstPrompt && !terminalManager.isLocked) {
                logModel.append(createMessage({
                    type: TerminalManager.MessageType.Prompt
                }));
                isFirstPrompt = false;
            }

            return;
        }

        if (_queue[0].instant) {
            const instantMsgs = [];

            while (terminalManager._queue[0]?.instant) {
                instantMsgs.push(terminalManager._queue.shift());
            }

            logModel.append(instantMsgs);
            cleanLogModel();
            return;
        }

        const minDelay = 200;
        const maxDelay = 400;
        const delay = Math.random() * maxDelay;

        _pendingMsg = _queue.shift();

        worker.interval = Utils.clamp(delay, minDelay, maxDelay);
        worker.start();
    }

    Timer {
        id: worker
        interval: 100

        onTriggered: terminalManager.processQueue()
    }
}
