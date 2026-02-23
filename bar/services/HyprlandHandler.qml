pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    property int selectedWorkspaceId: Hyprland.focusedWorkspace.id
}
