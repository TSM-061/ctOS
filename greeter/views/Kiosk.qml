import QtQuick
import Quickshell

import qs.greeter.components
import qs.greeter.config
import qs.common

// qmllint disable
FloatingWindow {
    id: window

    color: Theme.background

    // screen: {
    //     return Quickshell.screens.find(screen => screen.name === Settings.monitor);
    // }

    MainLayout {}
}
