import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.common
import qs.components

Item {
  id: root

  property int fontSize: Global.barClockFontSize
  property bool hovered: hoverHandler.hovered

  implicitWidth: Math.max(400, layout.implicitWidth + 32)
  implicitHeight: Global.reserveTop

  RowLayout {
    id: layout
    spacing: 8
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    SystemClock {
      id: clock
      precision: Global.barClockFormat.includes("ss") ? SystemClock.Seconds : SystemClock.Minutes
    }

    Label {
      text: Qt.formatDateTime(clock.date, Global.barClockFormat)
      font.bold: true
      font.pixelSize: root.fontSize
    }

    Label {
      visible: Global.barClockShowDate
      text: Qt.formatDateTime(clock.date, Global.barClockDateFormat)
      color: Theme.m3on_surface_variant
      font.weight: 500
      font.pixelSize: Math.max(11, root.fontSize - 2)
    }
  }

  HoverHandler {
    id: hoverHandler
  }
}
