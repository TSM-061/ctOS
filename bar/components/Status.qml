import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Services.Pipewire

import qs.common

Item {
    id: root

    readonly property font textFont: Qt.font({
        pixelSize: 16,
        family: Theme.fontFamily,
        weight: 500
    })

    height: parent.height
    width: frame.width + 6

    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink, Pipewire.defaultAudioSource]
    }

    CornerFrame {
        id: frame

        anchors.centerIn: parent
        height: parent.height - 6

        RowLayout {
            id: layout

            spacing: 0

            SystemClock {
                id: systemClock
                precision: SystemClock.Seconds
            }
            Text {
                text: Qt.formatDateTime(systemClock.date, "ddMMyy")
                color: Theme.textSecondary
                font: root.textFont
            }
            Text {
                text: `-${Qt.formatDateTime(systemClock.date, "hhmm")}-`
                color: Theme.textPrimary
                font: root.textFont
            }
            Text {
                text: "AEDT-1234-"
                color: Theme.textSecondary
                font: root.textFont
            }
            ScrollableValue {
                id: mic
                name: "MIC"
                textFont: root.textFont

                readonly property var sink: Pipewire.defaultAudioSource
                property var volume: (sink?.audio?.volume ?? 0) * 100

                Binding on value {
                    value: mic.volume
                }

                onValueChanged: {
                    mic.volume = mic.value;
                }
            }

            ScrollableValue {
                id: vol
                name: "VOL"
                textFont: root.textFont

                readonly property var sink: Pipewire.defaultAudioSink

                value: (sink?.audio?.volume ?? 0) * 100
                suppressed: !!sink?.audio?.muted

                onToggleSupressed: {
                    sink.audio.muted = !sink.audio.muted;
                }

                onValueScrolled: delta => {
                    sink.audio.muted = false;
                    const newVolume = sink.audio.volume + delta / 100;
                    sink.audio.volume = Utils.clamp(newVolume, 0, 1);
                }
            }
        }
    }
}
