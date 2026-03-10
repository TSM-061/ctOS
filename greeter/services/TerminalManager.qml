pragma Singleton

import QtQuick
import Quickshell

import qs.common
import qs.greeter.config

Singleton {
    id: terminalManager

    property var _queue: []

    property var logModel: ListModel {}

    signal paused(string pauseMarker)

    property bool isPaused: false

    property string pauseMarker

    Timer {
        id: worker
        repeat: true
        interval: 1
        onTriggered: () => {
            if (terminalManager._queue.length === 0) {
                terminalManager.logModel.append(terminalManager._createItem({
                    type: "prompt",
                    pauseMarker: "PROMPT"
                }));
                worker.stop();
                worker.interval = 1;
                return;
            }

            // Flush the entire leading instant run atomically — no per-item delay
            if (terminalManager._queue[0].instant) {
                while (terminalManager._queue[0]?.instant) {
                    terminalManager._addToModel(terminalManager._queue.shift());
                }
                return;
            }

            const item = terminalManager._queue.shift();
            terminalManager._addToModel(item);

            // Prompt items hand off control to the Terminal delegate
            if (item.type === "prompt") {
                worker.stop();
                worker.interval = 1;
                return;
            }

            if (item.pauseWithMarker) {
                worker.stop();
                terminalManager.paused(item.pauseWithMarker);
                return;
            }

            const minDelay = 1;
            const maxDelay = 300;
            const delay = Math.random() * maxDelay;
            worker.interval = Utils.clamp(delay, minDelay, maxDelay);
        }
    }

    function _addToModel(item) {
        logModel.append(item);

        if (logModel.count > 50) {
            logModel.remove(0);
        }
    }

    function notifyReady() {
        if (!worker.running) {
            worker.start();
        }
    }

    function _createItem(overrides) {
        const base = {
            type: "output",
            instant: false,
            message: "",
            animateTo: "",
            pauseWithMarker: "",
            animateTo: ""
        };

        const extra = overrides || {};
        return Object.assign(base, extra);
    }

    function displayMessage(message: string, options = {
        pauseWithMarker: "",
        instant: false
    }) {
        const {
            pauseWithMarker = "",
            instant = false
        } = options;

        const item = terminalManager._createItem({
            type: "output",
            instant,
            message,
            pauseWithMarker
        });

        terminalManager._queue.push(item);

        if (!worker.running) {
            worker.start();
        }
    }

    function displayMessages(messages: var, options = {
        pauseWithMarker: "",
        instant: false
    }) {
        const {
            pauseWithMarker = "",
            instant = false
        } = options;

        const items = messages.map(msg => terminalManager._createItem({
                type: "output",
                instant,
                message: msg,
                pauseWithMarker
            }));

        terminalManager._queue.push(...items);

        if (!worker.running)
            worker.start();
    }

    function unPause() {
        isPaused = false;
        worker.start();
    }

    // Enqueue a prompt that will typewrite `text` into the input, then call `callback`.
    function displayPrompt(text: string) {
        terminalManager._queue.push(terminalManager._createItem({
            type: "prompt",
            animateTo: text
        }));
        if (!worker.running)
            worker.start();
    }

    Component.onCompleted: {
        displayMessage("REGION_LINK_ESTABLISHED : AU-SOUTH-EAST-2");
        displayMessage("LOG_STREAM_CONNECTED // 1B7C5296-469D-4595-AD5D-4E31349CF13F");

        displayMessage(`WL_OUTPUT_FOUND: ${Settings.monitor} <-> ADDR_PTR: 0x${Faker.randomHexString()}`);
        displayMessage("---GREETER_UI_INITIALIZING---", {
            pauseWithMarker: "UI_INIT"
        });
    }
}
