pragma Singleton

import QtQuick
import Quickshell

import qs.bar.config
import qs.bar.services

Singleton {
    id: manager

    property var _handler

    property int selectedWorkspaceId

    Component.onCompleted: {
        if (Desktop.compositor === Desktop.Compositor.Hyprland) {
            _handler = HyprlandHandler;
        } else {
            throw new Error("Compositor not supported.");
        }

        manager.selectedWorkspaceId = _handler.selectedWorkspaceId;
    }

    Connections {
        target: manager._handler
        function onSelectedWorkspaceIdChanged() {
            debounceTimer.restart();
        }
    }

    Timer {
        id: debounceTimer
        interval: 10
        onTriggered: manager.selectedWorkspaceId = manager._handler.selectedWorkspaceId
    }
}
