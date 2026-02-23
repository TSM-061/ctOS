import QtQuick
import QtQuick.Layouts

import qs.common

Item {
    id: root

    focus: mouseArea.hovered

    property string name: ""
    property int value: 0
    property bool suppressed: false

    property font textFont

    implicitWidth: layout.implicitWidth
    implicitHeight: layout.implicitHeight

    RowLayout {
        id: layout
        anchors.fill: parent
        spacing: 0

        Text {
            text: root.name
            color: mouseArea.hovered ? Theme.textPrimary : Theme.textSecondary
            font: root.textFont
        }

        Text {
            text: root.suppressed ? "000" : root.value.toString().padStart(3, '0')
            color: mouseArea.hovered ? Theme.success : Theme.textSecondary
            font: root.textFont
        }
    }

    signal toggleSupressed
    signal valueScrolled(int delta)

    TapHandler {
        onTapped: {
            root.toggleSupressed();
        }
    }

    HoverHandler {
        id: mouseArea
    }

    WheelHandler {
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        onWheel: event => {
            const step = event.modifiers & Qt.ShiftModifier ? 10 : 1;
            root.valueScrolled(event.angleDelta.y > 0 ? step : -step);
        }
    }
}
