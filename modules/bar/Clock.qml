import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.common
import qs.components

Item {
  // Give the root item a physical size based on its contents
  implicitWidth: 400
  implicitHeight: Global.reserveTop

  RowLayout {
    id: layout
    spacing: 6
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.verticalCenter: parent.verticalCenter

    SystemClock {
      id: clock
      precision: SystemClock.Minutes
    }

    Label {
      text: Qt.formatDateTime(clock.date, "HH:mm")
      // color: Theme.m3on_surface
      font.bold: true
      font.pixelSize: 16
    }
  }
}
