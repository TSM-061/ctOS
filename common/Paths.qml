pragma Singleton
import QtQuick
import Quickshell

Singleton {
    readonly property string localConfigDir: `${Quickshell.env("HOME")}/.config/ctos`
    readonly property string globalConfigDir: "/etc/ctos"
    readonly property string stateDir: "/var/lib/ctos"

    function globalConfigPath(fileName: string): string {
        return `${globalConfigDir}/${fileName}.json`;
    }

    function localConfigPath(fileName: string): string {
        return `${localConfigDir}/${fileName}.json`;
    }

    function statePath(fileName: string): string {
        return `${stateDir}/${fileName}.json`;
    }
}
