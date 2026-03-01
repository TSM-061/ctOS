pragma ComponentBehavior: Bound
import QtQuick

import qs.common
import qs.greeter.services

Rectangle {

    ListView {
        id: view

        width: 300
        height: 300

        highlight: Rectangle {
            color: Theme.ctosGray
        }

        model: DesktopService.sessions

        spacing: 5 * Units.vh

        delegate: Text {
            id: option
            required property int index
            required property var modelData

            property bool isSelected: index === view.currentIndex

            width: view.width
            text: modelData.name || "n/a"
            color: option.isSelected ? Theme.background : Theme.textPrimary

            font {
                pixelSize: 18
                family: Theme.fontFamily
            }

            TapHandler {
                onTapped: view.currentIndex = option.index
            }

            HoverHandler {
                id: hover
            }
        }
    }
}
