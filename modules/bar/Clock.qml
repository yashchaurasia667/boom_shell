import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.common
import qs.components

Item {
  id: root

  property int fontSize: 16
  property bool hovered: hoverHandler.hovered

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
      font.bold: true
      font.pixelSize: root.fontSize
    }

    // Label {
    //   // width: root.hovered ? 100 : 0
    //   text: Qt.formatDateTime(clock.date, "ddd dd MMM")
    //   color: Theme.m3on_primary_fixed_variant
    //   font.weight: 500
    //   font.pixelSize: root.fontSize
    //
    //   Behavior on width {
    //     Anim {}
    //   }
    // }
  }

  HoverHandler {
    id: hoverHandler
  }
}
