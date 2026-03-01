import QtQuick

import qs.greeter.services
import qs.greeter.components
import qs.greeter.config
import qs.common
import qs.common.components

Item {
    id: root

    anchors.fill: parent

    focus: true

    Keys.onPressed: event => {
        // Disable Ctrl + C exiting
        if (event.key === Qt.Key_C && (event.modifiers & Qt.ControlModifier)) {
            event.accepted = true;
        }

        if (Settings.isDebug) {
            switch (event.key) {
            case Qt.Key_F12:
                AuthManager.state = AuthManager.State.Success;
                break;
            case Qt.Key_Escape:
                Qt.quit();
                break;
            }
        }
    }

    Image {
        id: backgroundImage
        anchors.fill: parent
        source: "../resources/lock.png"
    }

    Splash {
        id: splash

        width: 294 * Units.vh
        height: 48 * Units.vh

        anchors {
            horizontalCenter: parent.horizontalCenter
            verticalCenter: root.top
            verticalCenterOffset: root.height * 0.406
        }
    }

    Connections {
        target: accents

        function onFinished() {
            splash.start();
        }
    }

    Accents {
        id: accents

        state: "splash"
        states: [
            State {
                name: "splash"

                AnchorChanges {
                    target: accents

                    anchors {
                        top: splash.top
                        right: splash.right
                        bottom: splash.bottom
                        left: splash.left
                    }
                }
            },
            State {
                name: "field_group"

                AnchorChanges {
                    target: accents

                    anchors {
                        top: fieldGroup.top
                        right: fieldGroup.right
                        bottom: fieldGroup.bottom
                        left: fieldGroup.left
                    }
                }
            }
        ]

        transitions: Transition {
            id: accentTransition
            from: "*"
            to: "*"

            AnchorAnimation {
                duration: 400
                easing.type: Easing.InOutCirc
            }
        }
    }

    FieldGroup {
        id: fieldGroup

        anchors {
            top: splash.bottom
            topMargin: 50 * Units.vh

            horizontalCenter: root.horizontalCenter
        }
    }

    Disclaimer {
        id: disclaimer

        anchors {
            left: splash.left
            right: splash.right
            top: splash.bottom
            topMargin: 25 * Units.vh + 50 * Units.vh + 85 * Units.vh + 15 * Units.vh
            leftMargin: 2
        }
    }

    Time {
        id: time

        anchors {
            top: root.top
            left: root.left
            leftMargin: root.height * 0.05
            topMargin: root.height * 0.05
        }
    }

    Terminal {
        id: terminal
        logModel: TerminalManager.logModel
        anchors {
            bottom: parent.bottom
            left: parent.left
            // visual fix on border, subpixel gets smoothed
            leftMargin: Math.round(parent.width * 0.037)
            bottomMargin: Math.round(parent.height * 0.046)
        }
        width: 94.5 * terminal.rem
    }

    Session {
        id: session
        anchors {
            right: root.right
            top: root.top
            rightMargin: root.height * 0.0375
            topMargin: root.height * 0.046
        }
    }

    DeviceId {
        id: device

        height: root.height * 0.45

        anchors {
            right: root.right
            bottom: root.bottom

            rightMargin: root.height * 0.0375
            bottomMargin: root.height * 0.046
        }
    }

    SequentialAnimation {
        id: startSplash
        running: Settings.animationProfile(Settings.AnimationMode.All)

        PropertyAction {
            target: disclaimer
            property: "opacity"
            value: 0
        }

        ScriptAction {
            script: startSplash.pause()
        }

        // prevents race where pause allows further instructions to be executed
        // if not time-based, e.g. splash.start()
        PauseAnimation {}

        ParallelAnimation {
            ScriptAction {
                script: accents.start()
            }

            NumberAnimation {
                target: disclaimer
                property: "opacity"
                to: 1
                duration: 100
                easing.type: Easing.InCubic
            }
        }
    }

    SequentialAnimation {
        id: startupAnimation
        running: Settings.animationProfile(Settings.AnimationMode.All)

        // SECTION Setup

        PropertyAction {
            target: splash
            property: "anchors.verticalCenterOffset"
            value: root.height / 2
        }
        PropertyAction {
            target: disclaimer
            property: "anchors.topMargin"
            value: 25 * Units.vh
        }
        PropertyAction {
            target: fieldGroup
            property: "opacity"
            value: 0
        }

        ScriptAction {
            script: startupAnimation.pause()
        }

        // SECTION Begin

        ParallelAnimation {
            id: slideApart

            NumberAnimation {
                target: splash
                property: "anchors.verticalCenterOffset"
                to: root.height * 0.406
                duration: 500
                easing.type: Easing.InOutCirc
            }

            NumberAnimation {
                target: disclaimer
                property: "anchors.topMargin"
                to: 25 * Units.vh + fieldGroup.anchors.topMargin + 85 * Units.vh + 15 * Units.vh
                duration: 500
                easing.type: Easing.InOutCirc
            }

            SequentialAnimation {
                PauseAnimation {
                    duration: 300
                }

                NumberAnimation {
                    target: fieldGroup
                    property: "opacity"
                    to: 1
                    duration: 200
                    easing.type: Easing.OutExpo
                }
            }
        }

        onFinished: TerminalManager.unPause()
    }

    SequentialAnimation {
        id: exitAnimation
        running: AuthManager.state === AuthManager.State.Success

        ScriptAction {
            script: accents.state = "field_group"
        }

        PauseAnimation {
            duration: 200
        }

        ScriptAction {
            script: disclaimer.exit()
        }
        PauseAnimation {
            duration: 200
        }

        ScriptAction {
            script: fieldGroup.start()
        }
    }

    Connections {
        target: TerminalManager

        function onPaused(marker: string) {
            if (Settings.animationProfile(Settings.AnimationMode.Reduced)) {
                // startup sequence won't run so manually unpause
                TerminalManager.unPause();
            }

            if (marker == "UI_INIT") {
                startSplash.resume();
            }
        }
    }

    Connections {
        target: splash

        function onProgressBarMidway() {
            time.start();
            device.start();
            status.start();
        }

        function onRevealFinished() {
            startupAnimation.resume();
        }
    }

    Connections {
        target: fieldGroup

        function onFinished() {
            AuthManager.finish();
        }
    }
}
