import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.common
import qs.components
import qs.services

Item {
  implicitWidth: row.implicitWidth + Global.pad
  // implicitHeight: row.implicitHeight
  implicitHeight: Global.pillHeight - 10
  readonly property int usage: Math.round(SystemStatsService.cpuUsage)
  readonly property int temp: Math.round(SystemStatsService.cpuTemp)

  Rectangle {
    anchors.fill: parent
    radius: Global.earRadius
    color: Theme.m3surface_variant
  }

  RowLayout {
    id: row
    anchors.fill: parent
    anchors.leftMargin: Global.pad /2
    anchors.rightMargin: Global.pad /2
    spacing: 6

    Icon {
      text: "memory"
      color: Theme.m3on_surface
    }

    Label {
      text: usage + "%"
      font.bold: true
      color: usage > 90 ? Theme.m3error : Theme.m3on_surface
    }

    Label {
      text: " | "
      font.bold: true
      color: usage > 90 ? Theme.m3error : Theme.m3on_surface
    }

    Label {
      text: temp + "°C"
      font.bold: true
      color: temp > 85 ? Theme.m3error : Theme.m3on_surface
    }

    Icon {
      text: "device_thermostat"
      color: temp > 85 ? Theme.m3error : Theme.m3on_surface
    }
  }

}
