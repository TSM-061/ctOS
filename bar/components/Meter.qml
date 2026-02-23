import QtQuick
import QtQuick.Layouts

import qs.common
import qs.bar.components

Item {
    id: root

    property int percentage: 65
    property string name: "CPU"
    property string symbol: "<>"
    property string value: "65"

    height: parent.height
    width: frame.width + 6

    CornerFrame {
        id: frame

        anchors.centerIn: parent
        height: parent.height - 6

        ColumnLayout {
            id: layout

            y: -2
            width: 90
            spacing: 1

            RowLayout {
                id: topRow
                spacing: 2

                Text {
                    id: text1
                    text: root.name
                    color: "white"
                    font.pixelSize: 12
                    font.weight: 600
                    font.family: Theme.fontFamily
                }

                Text {
                    id: text2
                    text: root.symbol
                    color: "white"
                    font.pixelSize: 12
                    font.weight: 600
                    font.family: Theme.fontFamily
                }

                Item {
                    Layout.fillWidth: true
                }

                Text {
                    id: text3
                    text: root.value
                    color: "white"
                    font.pixelSize: 12
                    font.weight: 600
                    font.family: Theme.fontFamily
                }
            }

            Rectangle {
                id: bottomRect
                Layout.fillWidth: true
                Layout.preferredHeight: 3
                color: Theme.secondary

                Rectangle {
                    anchors.fill: parent
                    color: Theme.ctosGray
                    transform: Scale {
                        origin.x: 0
                        xScale: Utils.clamp(root.percentage, 0, 100) / 100

                        Behavior on xScale {
                            NumberAnimation {
                                duration: 1000
                                easing.type: Easing.InOutSine
                            }
                        }
                    }
                }
            }
        }
    }
}
