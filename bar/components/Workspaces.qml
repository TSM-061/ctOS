pragma ComponentBehavior: Bound
import QtQuick

import qs.bar.services

Row {
    id: root

    property int count: 5
    property int selectedIndex: WorkspaceManager.selectedWorkspaceId - 1  // workspace 1-based index

    width: parent.height * 5 + (count - 1)
    height: parent.height

    Repeater {
        model: root.count

        Row {
            required property int index

            height: parent.height
            Workspace {
                id: workspace
                active: parent.index === root.selectedIndex
            }

            Divider {}
        }
    }
}
