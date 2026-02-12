import QtQuick
import Quickshell

import "../Components"
import "../Config"
import "../Common"

// qmllint disable
FloatingWindow {
    id: window

    color: Theme.background

    // screen: {
    //     return Quickshell.screens.find(screen => screen.name === Settings.monitor);
    // }

    MainLayout {}
}
