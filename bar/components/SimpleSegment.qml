import QtQuick
import QtQuick.Layouts
import qs.common

Item {
    id: root
    property string text: "TEXT"

    height: parent.height
    width: frame.width + 6

    default property alias icon: icon.data

    CornerFrame {
        id: frame

        anchors.centerIn: parent
        height: parent.height - 6

        RowLayout {
            id: layout

            spacing: 5
            Item {
                id: icon
                Layout.preferredHeight: text.height - 2 * Units.vh
                Layout.preferredWidth: text.height - 2 * Units.vh
            }

            Text {
                id: text
                text: root.text
                color: Theme.textPrimary
                font.pixelSize: 16
                font.family: Theme.fontFamily
                font.weight: 500
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
