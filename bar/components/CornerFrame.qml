pragma ComponentBehavior: Bound
import QtQuick

Item {
    id: root

    property color accentColor: "white"
    property int thickness: 1
    property int armLength: 7
    property int horizontalMargin: 4

    implicitWidth: container.width + 2 * armLength + 2 * horizontalMargin
    width: implicitWidth

    implicitHeight: container.height + 2 * armLength
    height: implicitHeight

    default property alias content: container.data

    Row {
        id: container
        x: root.armLength + root.horizontalMargin
        y: root.armLength - 2  // visual fix
    }

    component Corner: Item {
        width: root.armLength
        height: root.armLength

        Rectangle {
            width: root.armLength
            height: root.thickness
            color: root.accentColor
            anchors.top: parent.top
            anchors.left: parent.left
        }

        Rectangle {
            width: root.thickness
            height: root.armLength
            color: root.accentColor
            anchors.top: parent.top
            anchors.left: parent.left
        }
    }

    property int count: 2

    Corner {
        id: topLeft
        anchors.top: parent.top
        anchors.left: parent.left
    }

    Corner {
        id: topRight
        anchors.top: parent.top
        anchors.right: parent.right
        rotation: 90
    }

    Corner {
        id: bottomRight
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        rotation: 180
    }

    Corner {
        id: bottomLeft
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        rotation: 270
    }
}
