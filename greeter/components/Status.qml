import QtQuick
import QtQuick.Layouts

import Quickshell.Services.UPower

import qs.common
import qs.greeter.config

Surface {
    id: root
    margins: 18
    barColor: Qt.darker(Theme.textPrimaryDimmer, 2)
    topMargin: 14
    bottomMargin: 14

    component InfoField: ColumnLayout {
        id: field
        property string label: "FIELD"
        property string value: "VALUE"
        property alias fieldValueOpacity: fieldValue.opacity

        Text {
            id: fieldLabel
            text: field.label
            color: Theme.textPrimaryDim
            font {
                family: Settings.fontFamily
                pixelSize: 12
            }
        }

        Text {
            id: fieldValue
            text: field.value
            color: Theme.textPrimary
            font {
                family: Settings.fontFamily
                pixelSize: 18
                weight: 500
            }
        }
    }

    property var battery: UPower.devices.values.find(d => d.isLaptopBattery) || null
    property var batteryPercentage: battery ? Math.round(root.battery.percentage * 100) : -1 // not real percentage is a decimal

    ColumnLayout {
        spacing: 10

        RowLayout {
            id: row
            spacing: 30

            InfoField {
                Layout.fillWidth: true
                label: root.battery ? "BATTERY" : "ENV"
                value: root.battery ? `${root.batteryPercentage}%` : Settings.fakeStatus.env
            }

            InfoField {
                Layout.fillWidth: true
                label: "NODE"
                value: Settings.fakeStatus.node
            }
        }
    }
}
