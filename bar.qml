import Quickshell
import QtQuick
import QtQuick.Layouts

import qs.common
import qs.bar.components

// qmllint disable
PanelWindow {
    id: root

    color: Theme.background
    focusable: true

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

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Row {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignLeft

            SystemLabel {
                anchors.top: parent.top
                anchors.bottom: parent.bottom
            }

            Divider {}

            Workspaces {}

            Meter {
                name: "CPU"
                symbol: "<>"
                value: "2.4Ghz"
                percentage: 60
            }
            Divider {}
            Meter {
                name: "MEM"
                symbol: "##"
                value: "8Gb"
                percentage: 50
            }
            Divider {}
        }

        Item {
            Layout.fillWidth: true
        }

        Row {
            Layout.fillHeight: true
            Layout.alignment: Qt.AlignRight

            SimpleSegment {
                text: Quickshell.env("USER").toUpperCase()
                Text {
                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -1

                    text: "▨"
                    color: Theme.textPrimary
                    font.pixelSize: 18
                    font.family: Theme.fontFamily
                    font.weight: 600
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            Divider {}

            Status {}
        }
    }
}
