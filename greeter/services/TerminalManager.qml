pragma Singleton

import QtQuick
import Quickshell

import qs.common
import qs.greeter.config

Singleton {
    id: terminalManager

    property var logModel: ListModel {}

    property var _queue: []

    signal paused(string pauseMarker)

    property bool isPaused: false

    property int currentState: TerminalManager.State.Booting
    property var _serviceRegistry: []

    readonly property bool isLocked: {
        for (var i = 0; i < _serviceRegistry.length; i++) {
            if (_serviceRegistry[i].locked)
                return true;
        }
        return false;
    }

    enum State {
        Booting,
        Interactive,
        Busy,
        TearDown
    }

    function registerService(serviceId) {
        _serviceRegistry.push({
            id: serviceId,
            locked: true
        });

        _serviceRegistryChanged();
    }

    function unlock(serviceId) {
        const service = _serviceRegistry.find(s => s.id === serviceId);

        if (!service) {
            throw new Error(`Service not registered: '${serviceId}'`);
        }

        service.locked = false;
        _serviceRegistryChanged();

        checkTransition();
    }

    function _unlockAll() {
        _serviceRegistry.forEach(s => s.locked = false);
        _serviceRegistryChanged();
        checkTransition();
    }

    function checkTransition() {
        if (!isLocked && currentState === TerminalManager.State.Booting) {
            terminalManager.currentState = (TerminalManager.State.Interactive);
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
            pauseWithMarker: ""
        };

        const extra = overrides || {};
        return Object.assign(base, extra);
    }

    function displayMessage(message: string, options = {}) {
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

    function resume() {
        isPaused = false;
        worker.start();
    }

    Component.onCompleted: {
        terminalManager.registerService(terminalManager.toString());

        displayMessage("REGION_LINK_ESTABLISHED : AU-SOUTH-EAST-2");
        displayMessage("LOG_STREAM_CONNECTED // 1B7C5296-469D-4595-AD5D-4E31349CF13F");
        displayMessage(`WL_OUTPUT_FOUND: ${Settings.monitor} <-> ADDR_PTR: 0x${Faker.randomHexString()}`);
        displayMessage("---GREETER_UI_INITIALIZING---", {
            pauseWithMarker: "UI_INIT"
        });
    }

    Timer {
        id: worker
        repeat: true
        interval: 1
        onTriggered: () => {
            if (terminalManager._queue.length === 0) {
                // terminalManager.logModel.append(terminalManager._createItem({
                //     type: "prompt",
                //     pauseMarker: "PROMPT"
                // }));
                worker.stop();
                // worker.interval = 1;
                return;
            }

            // Flush the entire leading instant run atomically — no per-item delay
            // if (terminalManager._queue[0].instant) {
            //     while (terminalManager._queue[0]?.instant) {
            //         terminalManager._addToModel(terminalManager._queue.shift());
            //     }
            //     return;
            // }

            const item = terminalManager._queue.shift();
            terminalManager._addToModel(item);

            if (item.pauseWithMarker) {
                worker.stop();
                terminalManager.paused(item.pauseWithMarker);
                return;
            }

            // Prompt items hand off control to the Terminal delegate
            // if (item.type === "prompt") {
            //     worker.stop();
            //     worker.interval = 1;
            //     return;
            // }

            const minDelay = 200;
            const maxDelay = 400;
            const delay = Math.random() * maxDelay;
            worker.interval = Utils.clamp(delay, minDelay, maxDelay);
        }
    }
}
