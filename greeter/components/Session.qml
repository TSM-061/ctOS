import QtQuick
import QtQuick.Layouts

import qs.common

RowLayout {
    spacing: 0
    ColumnLayout {
        id: code
        Layout.alignment: Qt.AlignTop

        RowLayout {
            spacing: 0
            Rectangle {
                color: Theme.ctosGray
                height: 56 * Units.vh
                width: height

                Image {
                    anchors.fill: parent
                    anchors.margins: 2 * Units.vh
                    fillMode: Image.PreserveAspectFit
                    source: "../resources/blume-logo.svg"
                }
            }

            ColumnLayout {
                Layout.preferredWidth: 150 * Units.vh

                spacing: 0

                Rectangle {
                    color: Theme.backgroundBright
                    Layout.fillWidth: true
                    Layout.preferredHeight: 28 * Units.vh

                    RowLayout {
                        anchors {
                            fill: parent
                            leftMargin: 10 * Units.vh
                            rightMargin: 10 * Units.vh
                        }

                        Text {
                            color: Theme.textPrimary
                            text: "TOMTOM"
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Image {
                            Layout.preferredWidth: 15 * Units.vh
                            Layout.preferredHeight: width
                            source: "../resources/tesseract.svg"
                        }
                    }
                }

                Rectangle {
                    id: barcode

                    Layout.preferredHeight: 28 * Units.vh
                    Layout.fillWidth: true
                    color: Theme.ctosGray

                    Image {
                        anchors.fill: parent
                        anchors.margins: 5 * Units.vh
                        fillMode: Image.PreserveAspectFit
                        source: "../resources/user-barcode.svg"
                    }
                }
            }
        }
    }

    Rectangle {
        id: picture

        color: Theme.secondary
        height: 75 * Units.vh
        width: height

        Image {
            // TODO add proper profile picture
            source: "../resources/user.svg"
            anchors.fill: parent
        }
    }
}
