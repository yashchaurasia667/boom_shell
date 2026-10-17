import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.UPower

import qs.common
import qs.components

Item {
  readonly property int charge: Math.round(UPower.displayDevice.percentage * 100)
  readonly property string batColor: {
    if(charge >= 90) return Theme.m3primary
    if(charge >= 50) return Theme.m3tertiary
    if(charge >= 20) return Theme.m3error
    return Theme.m3error_container
  }

  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  visible: UPower.displayDevice.isLaptopBattery

  RowLayout {
    id: row
    anchors.fill: parent
    spacing: 6

    Icon {
      text: {
        const d = UPower.displayDevice
        if (d.state === UPowerDeviceState.Charging) return "battery_android_frame_bolt"
        const pct = d.percentage * 100
        if (pct <= 25) return "battery_android_1"
        if (pct <= 50) return "battery_android_3"
        if (pct <= 75) return "battery_android_4"
        if (pct <= 95) return "battery_android_6"
        return "battery_android_full"
      }
      color: batColor
      font.pixelSize: 18
    }

    Label {
      text: charge + "%"
      font.bold: true
      font.pixelSize: 14
      color: batColor
    }
  }
}
