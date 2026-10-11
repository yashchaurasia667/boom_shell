import QtQuick
import QtQuick.Layouts

import qs.common
import qs.components
import qs.services

ColumnLayout {
  spacing: 10

  RowLayout {
    Layout.fillWidth: true
    spacing: 12

    Rectangle {
      Layout.preferredWidth: 56
      Layout.preferredHeight: 56
      radius: 10
      color: Theme.m3surface_variant
      clip: true

      Image {
        anchors.fill: parent
        visible: MprisService.artUrl !== ""
        source: MprisService.artUrl
        fillMode: Image.PreserveAspectCrop
      }

      Icon {
        visible: MprisService.artUrl === ""
        anchors.centerIn: parent
        text: "music_note"
        font.pixelSize: 24
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 2

      Label {
        Layout.fillWidth: true
        text: MprisService.hasPlayer ? MprisService.title : "Nothing playing"
        font.bold: true
        font.pixelSize: 14
        elide: Text.ElideRight
      }

      Label {
        Layout.fillWidth: true
        visible: MprisService.artist !== ""
        text: MprisService.artist
        font.pixelSize: 12
        color: Theme.m3on_surface
        elide: Text.ElideRight
      }
    }
  }

  // seek bar — reuses your existing horizontal Slider directly
  Slider {
    Layout.fillWidth: true
    Layout.preferredHeight: 5   // thinner seek bar, was the default 32
    Layout.topMargin: Global.pad
    enabled: MprisService.canSeek
    from: 0
    to: MprisService.length > 0 ? MprisService.length : 1
    value: {
      MprisService.positionTick
      return MprisService.position
    }
    onMoved: MprisService.setPosition(value)
  }

  RowLayout {
    Layout.alignment: Qt.AlignHCenter
    spacing: 20

    Icon {
      text: "skip_previous"
      font.pixelSize: 22
      MouseArea { anchors.fill: parent; onClicked: MprisService.previous() }
    }

    Icon {
      text: MprisService.playing ? "pause_circle" : "play_circle"
      font.pixelSize: 32
      color: Theme.m3primary
      MouseArea { anchors.fill: parent; onClicked: MprisService.togglePlaying() }
    }

    Icon {
      text: "skip_next"
      font.pixelSize: 22
      MouseArea { anchors.fill: parent; onClicked: MprisService.next() }
    }
  }
}
