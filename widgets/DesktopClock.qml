import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import qs.common
import qs.components

PanelWindow {
  id: root
  property int panelMargins: 20
  property string clockFont: "Changa One"

  anchors {
    left: true
  }
  exclusionMode: ExclusionMode.Ignore
  aboveWindows: false
  WlrLayershell.layer: WlrLayer.Bottom
  mask: Region {}

  implicitWidth: 400
  implicitHeight: 450
  color: "transparent"

  ColumnLayout {
    anchors.fill: parent
    anchors.leftMargin: panelMargins
    spacing: -20

    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: -125

      SystemClock {
        id: clock
        precision: SystemClock.Minutes
      }

      Label {
        text: Qt.formatDateTime(clock.date, "hh")
        font.family: clockFont
        font.pixelSize: 250
        color: Theme.m3primary

        style: Text.Raised
        styleColor: Theme.m3surface
      }
      Label {
        text: Qt.formatDateTime(clock.date, " mm")
        font.family: clockFont
        font.pixelSize: 250
        color: Theme.m3secondary

        style: Text.Raised
        styleColor: Theme.m3surface
      }
    }
    Label {
      text: Qt.formatDateTime(clock.date, "dddd, d MMMM yyyy")
      font.pixelSize: 32
      font.family: "Rowdies Light"
      color: Theme.m3on_error_container

      style: Text.Raised
      styleColor: Theme.m3surface
    }
  }
}
