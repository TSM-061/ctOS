pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import QtQml.Models

import qs.greeter.services
import qs.common
import qs.common.services
import qs.common.components
import qs.greeter.config

ColumnLayout {
    id: terminal

    property int margins: 10

    property int fontSize: 14 * Units.vh

    property int maxLines: {
        const totalSpace = Screen.height * 0.25;
        const takenSpace = version.height + terminal.spacing;

        const availableLines = (totalSpace - takenSpace) / lineHeight;
        return Utils.clamp(Math.floor(availableLines), 0, 10);
    }

    property int lineHeight: textMetrics.height + 5 * Units.vh
    property alias rem: textMetrics.width

    readonly property font font: Qt.font({
        family: Settings.fontFamily,
        pixelSize: terminal.fontSize
    })

    required property var logModel

    spacing: 15 * Units.vh

    TextMetrics {
        id: textMetrics
        font: terminal.font
        text: "-"
    }

    ListView {
        id: logView

        model: terminal.logModel
        clip: true

        Layout.fillWidth: true
        Layout.preferredHeight: terminal.lineHeight * terminal.maxLines

        boundsBehavior: Flickable.StopAtBounds
        verticalLayoutDirection: ListView.TopToBottom

        Behavior on contentY {
            id: scrollBehavior
            NumberAnimation {
                id: scrollAnimation
                duration: 50
                easing.type: Easing.OutCubic
            }
        }

        header: Item {
            id: headerItem
            width: logView.width
            height: logView.height
        }

        Connections {
            target: terminal.logModel

            function onCountChanged() {
                Qt.callLater(() => {
                    logView.contentY = -logView.height + terminal.logModel.count * terminal.lineHeight;
                });
            }
        }

        delegate: DelegateChooser {
            role: "type"

            DelegateChoice {
                roleValue: TerminalManager.MessageType.Output

                delegate: Item {
                    id: outputDelegate
                    width: logView.width
                    height: terminal.lineHeight

                    required property string message
                    required property string type
                    required property bool instant

                    Binding {
                        target: scrollAnimation
                        property: "duration"
                        value: outputDelegate.instant ? 0 : 50
                    }

                    Text {
                        id: entry

                        color: Theme.textPrimaryDimmer
                        font: terminal.font

                        lineHeight: terminal.lineHeight
                        lineHeightMode: Text.FixedHeight
                        wrapMode: Text.Wrap

                        width: logView.width

                        text: {
                            if (parent.message.startsWith("---")) {
                                const stripped = parent.message.replace(/-/g, "");

                                const spareRoom = Math.floor(terminal.width / textMetrics.advanceWidth) - 4 - (stripped.length);

                                const hyphenCount = Math.floor(spareRoom / 2);

                                return `${("-").repeat(hyphenCount)}  ${stripped}  ${("-").repeat(hyphenCount)}`;
                            }

                            return `${parent.message}`;
                        }
                    }
                }
            }

            DelegateChoice {
                roleValue: TerminalManager.MessageType.Prompt

                delegate: Row {
                    id: inputDelegate
                    width: logView.width
                    height: terminal.lineHeight

                    spacing: 0

                    required property bool instant
                    required property string syntheticCommand

                    Binding {
                        target: scrollAnimation
                        property: "duration"
                        value: inputDelegate.instant ? 0 : 50
                    }

                    Text {
                        id: terminalPrompt

                        property int charIndex: 0

                        property string command: inputDelegate.syntheticCommand

                        text: "» " + command.substr(0, charIndex)
                        color: Theme.textPrimaryDim
                        font: terminal.font
                        height: parent.height

                        onCommandChanged: {
                            typewriterAnimation.to = command.length;
                            typewriterAnimation.start();
                        }

                        NumberAnimation {
                            id: typewriterAnimation
                            target: terminalPrompt
                            property: "charIndex"
                            from: 0
                            easing.type: Easing.Linear
                        }
                    }

                    TextInput {
                        id: terminalInput

                        height: parent.height
                        width: parent.width - terminalPrompt.width

                        color: Theme.textPrimaryDim
                        font: terminal.font

                        enabled: !inputDelegate.syntheticCommand
                        focus: !inputDelegate.syntheticCommand

                        onAccepted: {
                            enabled = false;
                            focus = false;

                            CommandManager.sendCommand(terminalInput.text);
                        }

                        Keys.onUpPressed: {
                            terminalInput.text = CommandManager.previousHistory();
                            terminalInput.cursorPosition = terminalInput.text.length;
                        }

                        Keys.onDownPressed: {
                            terminalInput.text = CommandManager.nextHistory();
                            terminalInput.cursorPosition = terminalInput.text.length;
                        }

                        onActiveFocusChanged: {
                            if (activeFocus) {
                                FocusManager.requestFocus(terminalInput);
                            }
                        }

                        Component.onCompleted: {
                            FocusManager.registerTarget(terminalInput, {
                                tabIndex: 1
                            });
                        }
                    }
                }
            }
        }

        Component.onCompleted: {
            TerminalManager.notifyReady();
        }
    }

    Accents {
        id: accents

        opacityDuration: 200
        translateDuration: 300

        Layout.fillWidth: true
        Layout.preferredHeight: versionBorder.height

        SequentialAnimation {
            id: accentAnimation

            PauseAnimation {
                duration: 200
            }
            ScriptAction {
                script: accents.start()
            }
        }

        Component.onCompleted: {
            accentAnimation.start();
        }

        Rectangle {
            id: versionBorder

            color: "transparent"

            height: Math.round(version.height + 8)

            anchors {
                left: parent.left
                right: parent.right
            }

            border {
                color: Qt.darker(Theme.textPrimary, 1.6)
                width: 1
            }

            Text {
                id: version
                color: Qt.darker(Theme.textPrimary, 1.2)

                anchors {
                    verticalCenter: parent.verticalCenter
                    left: parent.left
                    leftMargin: 10
                }

                font {
                    pixelSize: 13 * Units.vh
                    family: Settings.fontFamily
                }

                text: "blume-krn-1.0.8 <> ctOS-1.0.0-a"
            }
        }
    }
}
