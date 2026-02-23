pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    enum Compositor {
        Hyprland,
        Niri,
        Unknown
    }

    readonly property int compositor: {
        const desktop = Quickshell.env("XDG_CURRENT_DESKTOP") || Quickshell.env("XDG_SESSION_DESKTOP") || "";
        const desktopLower = desktop.toLowerCase();

        if (desktopLower.includes("hyprland")) {
            return Desktop.Compositor.Hyprland;
        } else if (desktopLower.includes("niri")) {
            return Desktop.Compositor.Niri;
        }

        return Desktop.Compositor.Unknown;
    }
}
