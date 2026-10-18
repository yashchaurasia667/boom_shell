import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.common
import qs.components
import qs.services

Item {
  implicitWidth: row.implicitWidth + Global.pad
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
    anchors.leftMargin: Global.pad / 2
    anchors.rightMargin: Global.pad / 2
    spacing: 6

    Icon {
      text: "memory"
      color: Theme.m3on_surface
    }

    Label {
      text: usage + "%"
      font.bold: true
      color: usage > Global.cpuWarnThreshold ? Theme.m3error : Theme.m3on_surface
    }

    Label {
      visible: Global.barShowCpuTemp
      text: " | "
      font.bold: true
      color: usage > Global.cpuWarnThreshold ? Theme.m3error : Theme.m3on_surface
    }

    Label {
      visible: Global.barShowCpuTemp
      text: temp + "°C"
      font.bold: true
      color: temp > Global.tempWarnThreshold ? Theme.m3error : Theme.m3on_surface
    }

    Icon {
      visible: Global.barShowCpuTemp
      text: "device_thermostat"
      color: temp > Global.tempWarnThreshold ? Theme.m3error : Theme.m3on_surface
    }
  }
}
