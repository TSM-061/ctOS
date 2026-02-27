pragma ComponentBehavior: Bound
import QtQuick

import qs.common
import qs.greeter.services

ListView {
    id: view

    width: 200
    height: 300

    // currentIndex: 0

    model: DesktopService.sessions

    spacing: 5 * Units.vh

    delegate: Text {
        required property int index
        required property var modelData

        property bool isSelected: index === view.currentIndex

        text: `${isSelected ? "> " : "  "}${modelData.name || "n/a"}`
        color: Theme.textPrimary

        font {
            pixelSize: 18
            family: Theme.fontFamily
        }
    }
}
