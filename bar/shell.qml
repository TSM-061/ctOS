import Quickshell
import QtQuick

import qs.common
import qs.bar.components

// qmllint disable
PanelWindow {
    id: root

    color: Theme.background

    implicitHeight: 37

    anchors {
        top: true
        right: true
        left: true
    }

    Rectangle {
        anchors.fill: parent
        border {
            width: 1
            color: Theme.ctosGray
        }
        color: "transparent"
    }

    Row {
        anchors.fill: parent

        SystemLabel {
            anchors.top: parent.top
            anchors.bottom: parent.bottom
        }

        Divider {}

        Workspace {}

        Divider {}
    }
}
