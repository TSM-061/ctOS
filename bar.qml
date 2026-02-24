import Quickshell
import Quickshell.Io
import Quickshell.Networking
import QtQuick
import QtQuick.Layouts

import qs.common
import qs.common.components
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
                id: cpuMeter
                name: "CPU"
                symbol: "<>"
                value: "000%"
                percentage: 0

                property real lastCpuTotal: 0
                property real lastCpuIdle: 0
                Process {
                    id: cpuProc
                    command: ["sh", "-c", "while true; do head -1 /proc/stat; sleep 2; done"]
                    running: true
                    stdout: SplitParser {
                        onRead: data => {
                            if (!data) {
                                return;
                            }

                            const parts = data.trim().split(/\s+/);

                            const idle = parseInt(parts[4]) + parseInt(parts[5]);
                            const total = parts.slice(1, 8).reduce((a, b) => a + parseInt(b), 0);

                            if (cpuMeter.lastCpuTotal > 0) {
                                const cpuUsage = Math.round(100 * (1 - (idle - cpuMeter.lastCpuIdle) / (total - cpuMeter.lastCpuTotal)));

                                cpuMeter.percentage = cpuUsage;
                                cpuMeter.value = cpuUsage.toString().padStart(3, "0") + "%";
                            }

                            cpuMeter.lastCpuTotal = total;
                            cpuMeter.lastCpuIdle = idle;
                        }
                    }
                }
            }
            Divider {}
            Meter {
                id: memMeter
                name: "MEM"
                symbol: "##"
                value: "0.0G"
                percentage: 0

                Process {
                    id: memProc
                    command: ["sh", "-c", "while true; do free -m | awk '/^Mem:/ {print $2, $3}'; sleep 1; done"]
                    running: true
                    stdout: SplitParser {
                        onRead: data => {
                            if (!data) {
                                return;
                            }

                            const parts = data.trim().split(/\s+/);
                            if (parts.length < 2) {
                                return;
                            }

                            const total = parseInt(parts[0]);
                            let used = parseInt(parts[1]);

                            if (total > 0) {
                                const memUsagePercent = Math.round((used / total) * 100);

                                memMeter.percentage = memUsagePercent;
                                memMeter.value = (used / 1024).toFixed(1) + "G";
                            }
                        }
                    }
                }
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
                id: netSegment
                Accents {

                    anchors.fill: parent
                    animate: false

                    finalHorizontalOffset: -2
                    finalVerticalOffset: -2

                    individualSize: 2

                    Rectangle {
                        anchors.centerIn: parent
                        color: netSegment.text !== "--N/A--" ? Theme.success : Theme.secondary
                        height: parent.height * 0.4
                        radius: height / 2
                        width: height
                    }
                }

                text: {
                    let ssid = "";
                    let hasWifi = false;
                    let hasWired = false;

                    for (let i = 0; i < Networking.devices.values.length; i++) {
                        const device = Networking.devices.values[i];

                        if (device.type === DeviceType.None && device.connected) {
                            hasWired = true;
                            break;
                        }

                        if (device.type === DeviceType.Wifi && device.connected) {
                            hasWifi = true;
                            const connectedNetwork = device.networks.values.find(n => n.connected);

                            const wifiRegex = /([-_ ]?[25](?:\.4)?g)/gi;
                            ssid = (connectedNetwork?.name || "").toUpperCase().replace(wifiRegex, "");

                            const delimiterRegex = /[-_ ]/g;
                            ssid = ssid.replace(delimiterRegex, "").padEnd(7, "_");

                            ssid = ssid.length > 7 ? ssid.slice(-7) : ssid;
                        }
                    }

                    if (hasWired)
                        return "-WIRED-";

                    if (hasWifi && ssid !== "") {
                        return ssid;
                    }

                    return "--N/A--";
                }
            }

            Divider {}

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
