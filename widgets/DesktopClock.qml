import Quickshell
import Quickshell.Wayland
import QtQuick
import QtQuick.Layouts

import qs.common
import qs.components

PanelWindow {
  id: root
  property int panelMargins: Global.desktopClockMargins
  property string clockFont: Global.desktopClockFont
  property int fontSize: Global.desktopClockFontSize

  anchors {
    left: true
  }
  exclusionMode: ExclusionMode.Ignore
  aboveWindows: false
  WlrLayershell.layer: WlrLayer.Bottom
  mask: Region {}

  implicitWidth: Math.max(400, fontSize * 2 + panelMargins * 2)
  implicitHeight: Math.max(450, fontSize * 2 + 60)
  color: "transparent"

  ColumnLayout {
    anchors.fill: parent
    anchors.leftMargin: panelMargins
    spacing: -Math.round(root.fontSize * 0.4)

    ColumnLayout {
      Layout.fillWidth: true
      Layout.fillHeight: true
      spacing: -(root.fontSize / 2)

      SystemClock {
        id: clock
        precision: SystemClock.Minutes
      }

      Label {
        text: Qt.formatDateTime(clock.date, Global.desktopClock24h ? "HH" : "hh")
        font.family: clockFont
        font.pixelSize: root.fontSize
        color: Theme.m3primary

        style: Text.Raised
        styleColor: Theme.m3surface
      }
      Label {
        text: Qt.formatDateTime(clock.date, " mm")
        font.family: clockFont
        font.pixelSize: root.fontSize
        color: Theme.m3on_secondary_container

        style: Text.Raised
        styleColor: Theme.m3surface
      }
    }

    Label {
      text: Qt.formatDateTime(clock.date, Global.desktopClockDateFormat)
      font.pixelSize: Global.desktopClockDateSize
      font.family: Global.desktopClockDateFont
      color: Theme.m3on_error_container

      style: Text.Raised
      styleColor: Theme.m3surface
    }
  }
}
