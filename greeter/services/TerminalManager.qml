pragma Singleton

import QtQuick
import Quickshell

import qs.common
import qs.greeter.config
import qs.greeter.data

Singleton {
    id: terminalManager

    property int state: TerminalManager.State.Booting

    // actual model for output messages
    property var logModel: ListModel {}

    // buffer for storing messages generated before terminal is ready
    property list<var> _queue: []

    signal paused(string pauseMarker)

    // pausing prevents new output from being added
    property bool isPaused: false

    // locking means an input prompt won't be added
    property var _serviceLocks: []
    readonly property bool isLocked: _serviceLocks.some(service => service.locked)

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
        if (!worker.running) {
            worker.start();
        }
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

    function createPromptMessage() {
        return terminalManager.createMessage({
            type: TerminalManager.MessageType.Prompt,
            instant: true
        });
    }

    function createMessagesOptions(properties) {
        return {
            /* Is output from a user command. */
            isCommandOutput: properties?.isCommandOutput || false
        };
    }

    function displayMessages(messages: var, options) {
        if (!Array.isArray(messages)) {
            throw new Error("TerminalManager.displayMessages requires an array of message objects");
        }

        options = options || {};

        const {
            isCommandOutput
        } = createMessagesOptions(options);

        const items = messages.map(msg => createMessage(msg));

        if (isCommandOutput) {
            items.push(terminalManager.createPromptMessage());
        }

        // circumvent the queue when the terminal is interactive
        terminalManager._queue.push(...items);

        if (!worker.running) {
            worker.start();
        }
    }

    function resume() {
        isPaused = false;
        worker.start();
    }

    Component.onCompleted: {
        terminalManager.registerService(terminalManager);

        terminalManager.displayMessages([
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
    }

    Timer {
        id: worker
        repeat: true
        interval: 1

        onTriggered: () => {
            if (terminalManager._queue.length === 0) {
                worker.stop();

                if (!terminalManager.isLocked) {
                    // prompt goes straight to output
                    terminalManager.logModel.append(terminalManager.createPromptMessage());
                }

                return;
            }

            if (terminalManager._queue[0].instant) {
                const instantItems = [];

                while (terminalManager._queue[0]?.instant) {
                    instantItems.push(terminalManager._queue.shift());
                }

                terminalManager.logModel.append(instantItems);

                if (terminalManager.logModel.count > 50) {
                    terminalManager.logModel.remove(0, terminalManager.logModel.count - 50);
                }

                worker.interval = 1;
                return;
            }

            const item = terminalManager._queue.shift();
            terminalManager.logModel.append(item);

            if (terminalManager.logModel.count > 50) {
                terminalManager.logModel.remove(0);
            }

            if (item.unlock) {
                terminalManager.unlock(item.unlock);
            }

            if (item.pauseWithMarker) {
                worker.stop();
                terminalManager.paused(item.pauseWithMarker);
                return;
            }

            const minDelay = 200;
            const maxDelay = 400;
            const delay = Math.random() * maxDelay;
            worker.interval = Utils.clamp(delay, minDelay, maxDelay);
        }
    }
}
