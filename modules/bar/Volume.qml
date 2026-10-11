import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.services
import qs.components
import qs.common


Item {
  implicitWidth: row.implicitWidth
  implicitHeight: row.implicitHeight

  visible: AudioService.ready

  MouseArea {
    anchors.fill: parent
    acceptedButtons: Qt.LeftButton
    onClicked: AudioService.toggleMute()
    onWheel: (event) => {
      AudioService.nudgeVolume(event.angleDelta.y > 0 ? 0.05 : -0.05)
    }
  }

  RowLayout {
    id: row
    anchors.fill: parent
    spacing: 6

    Icon {
      text: {
        if (AudioService.muted) return "volume_off"
        const vol = AudioService.volume
        if (vol <= 0) return "volume_mute"
        if (vol <= 0.5) return "volume_down"
        return "volume_up"
      }
      color: Theme.m3on_surface
      font.pixelSize: 18
    }

    Label {
      text: AudioService.muted ? "muted" : Math.round(AudioService.volume * 100) + "%"
      font.bold: true
      font.pixelSize: 14
      color: Theme.m3on_surface
    }
  }
}
