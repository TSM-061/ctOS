import QtQuick
import Quickshell

import qs.greeter.components
import qs.greeter.config
import qs.common

// qmllint disable
PanelWindow {
    id: window

    anchors {
        top: true
        left: true
        right: true
        bottom: true
    }

    color: Theme.background

    exclusionMode: ExclusionMode.Ignore

    focusable: true

    screen: {
        return Quickshell.screens.find(screen => screen.name === Settings.monitor);
    }

    MainLayout {}
}
