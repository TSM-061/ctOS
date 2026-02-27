pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string localConfigDir: `${Quickshell.env("HOME")}/.config/ctos`
    readonly property string globalConfigDir: "/etc/ctos"
}
