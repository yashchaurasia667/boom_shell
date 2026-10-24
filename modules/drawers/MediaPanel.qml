import QtQuick
import QtQuick.Layouts

import qs.common
import qs.components
import qs.services

ColumnLayout {
  spacing: 10

  Component.onCompleted: MprisService.trackPosition = true
  Component.onDestruction: MprisService.trackPosition = false

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
        id: art
        anchors.fill: parent
        source: MprisService.artSource
        sourceSize: Qt.size(112, 112)      // 2x for HiDPI
        asynchronous: true
        cache: false                        // browsers reuse the same temp path for new art
        fillMode: Image.PreserveAspectCrop
        opacity: status === Image.Ready ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 150 } }

        // art often arrives before the file/URL is ready; retry a few times
        property int attempts: 0
        onSourceChanged: attempts = 0
        onStatusChanged: if (status === Image.Error && source != "" && attempts < 3) {
          console.warn("MediaPanel: failed to load art:", source, "(player url:", MprisService.artUrl + ")")
          retryTimer.restart()
        }

        Timer {
          id: retryTimer
          interval: 1200
          onTriggered: {
            art.attempts++
            const s = art.source
            art.source = ""
            art.source = s
          }
        }
      }

      Icon {
        visible: art.status !== Image.Ready
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
    onMoved: (value) => MprisService.setPosition(value)

    // Binding (unlike a plain `value:` expression) survives the user dragging the slider
    Binding on value {
      value: MprisService.position
    }
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
