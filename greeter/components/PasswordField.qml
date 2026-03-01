pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls

import qs.common

TextField {
    id: passwordField

    property alias rem: cursorMetrics.width

    font {
        pixelSize: 16
        letterSpacing: 5
    }

    echoMode: TextInput.Password

    passwordCharacter: "█"

    TextMetrics {
        id: cursorMetrics
        font: passwordField.font
        text: "▁"
    }

    leftPadding: 8
    rightPadding: cursorMetrics.width + 6  // fixes cursor going through border

    cursorDelegate: Text {
        id: cursor

        color: passwordField.color
        font: passwordField.font
        text: "▁"

        readonly property bool canBlink: passwordField.activeFocus && passwordField.enabled

        onCanBlinkChanged: {
            if (canBlink) {
                blinkAnimation.running = true;
            } else {
                blinkAnimation.running = false;
                cursor.opacity = 0;
            }
        }

        Connections {
            target: passwordField

            function onTextEdited() {
                blinkAnimation.restart();
                cursor.opacity = 1;
            }
        }

        SequentialAnimation on opacity {
            id: blinkAnimation

            loops: Animation.Infinite

            NumberAnimation {
                from: 1
                to: 1
                duration: 500
            }

            NumberAnimation {
                from: 1
                to: 0
                duration: 300
            }

            NumberAnimation {
                from: 0
                to: 0
                duration: 300
            }
        }
    }

    Component.onDestruction: {
        // in greeter, element will be focused as soon as it is created
        // graceful exit, wayland complains about surface with focus quitting
        passwordField.focus = false;
    }
}
