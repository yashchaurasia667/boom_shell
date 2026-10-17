import QtQuick
import QtQuick.Layouts

import qs.common
import qs.components
import qs.services

Rectangle {
  id: mediaCard

  property bool active: true
  property color cardColor: Theme.m3surface_bright
  property color artBgColor: Theme.m3surface_container_highest
  property color activeColor: Theme.m3primary
  property color activeContentColor: Theme.m3on_primary
  property color trackColor: Theme.m3surface_variant
  property color textPrimary: Theme.m3on_surface
  property color textSecondary: Theme.m3on_surface_variant

  implicitHeight: 198
  radius: 22
  color: mediaCard.cardColor
  clip: true

  Component.onCompleted: MprisService.trackPosition = true
  Component.onDestruction: MprisService.trackPosition = false

  function formatTime(sec: real): string {
    if (!sec || isNaN(sec) || sec < 0) return "0:00"
    const total = Math.floor(sec)
    const m = Math.floor(total / 60)
    const s = total % 60
    return m + ":" + (s < 10 ? "0" + s : s)
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 18
    spacing: 12

    // ── 1. Track Info Row (Album Art + Equalizer Badge / Title / Artist) ──
    RowLayout {
      Layout.fillWidth: true
      spacing: 14

      Rectangle {
        Layout.preferredWidth: 64
        Layout.preferredHeight: 64
        radius: 12
        color: mediaCard.artBgColor
        clip: true

        Image {
          anchors.fill: parent
          visible: MprisService.artUrl !== ""
          source: MprisService.artUrl
          sourceSize: Qt.size(128, 128)
          asynchronous: true
          cache: false
          fillMode: Image.PreserveAspectCrop
        }

        Icon {
          visible: MprisService.artUrl === ""
          anchors.centerIn: parent
          text: "music_note"
          font.pixelSize: 28
          color: mediaCard.textSecondary
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        // Equalizer Bars + Uppercase Player Identity (e.g. "SPOTIFY")
        RowLayout {
          spacing: 6

          Row {
            spacing: 2
            Layout.alignment: Qt.AlignVCenter

            Repeater {
              model: [10, 5, 8, 11]
              delegate: Rectangle {
                required property int modelData
                width: 2.5
                height: modelData
                radius: 1
                anchors.bottom: parent.bottom
                color: mediaCard.textPrimary
              }
            }
          }

          Label {
            text: (MprisService.activePlayer?.identity || "SPOTIFY").toUpperCase()
            font.pixelSize: 10
            font.bold: true
            font.letterSpacing: 1.2
            color: mediaCard.textSecondary
          }
        }

        Label {
          Layout.fillWidth: true
          text: MprisService.hasPlayer && MprisService.title !== ""
            ? MprisService.title
            : "Nothing playing"
          font.bold: true
          font.pixelSize: 16
          color: mediaCard.textPrimary
          elide: Text.ElideRight
        }

        Label {
          Layout.fillWidth: true
          text: MprisService.artist !== "" ? MprisService.artist : "No active media"
          font.pixelSize: 13
          color: mediaCard.textSecondary
          elide: Text.ElideRight
        }
      }
    }

    // ── 2. Wavy Seekbar Row ──
    RowLayout {
      id: seekRow
      Layout.fillWidth: true
      spacing: 10

      readonly property real currentPos: {
        MprisService.positionTick
        return MprisService.position
      }
      readonly property real totalLen: MprisService.length > 0 ? MprisService.length : 1
      readonly property real seekRatio: MprisService.length > 0
        ? Math.max(0, Math.min(1, currentPos / totalLen))
        : 0

      Label {
        text: mediaCard.formatTime(seekRow.currentPos)
        font.pixelSize: 12
        color: mediaCard.textSecondary
      }

      Item {
        id: waveSeekBar
        Layout.fillWidth: true
        Layout.preferredHeight: 22

        property real phase: 0

        Timer {
          interval: 50
          running: MprisService.playing && mediaCard.active && mediaCard.visible
          repeat: true
          onTriggered: {
            waveSeekBar.phase = (waveSeekBar.phase + 0.35) % (Math.PI * 2)
            waveCanvas.requestPaint()
          }
        }

        Connections {
          target: MprisService
          function onPositionTickChanged() { waveCanvas.requestPaint() }
          function onPlayingChanged() { waveCanvas.requestPaint() }
        }

        Canvas {
          id: waveCanvas
          anchors.fill: parent
          onWidthChanged: requestPaint()
          onHeightChanged: requestPaint()

          onPaint: {
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            const cy = height / 2
            const ratio = seekRow.seekRatio
            const splitX = Math.max(4, Math.min(width - 4, ratio * width))
            const amp = MprisService.hasPlayer ? 3.5 : 0
            const waveLen = 22

            // Unplayed flat track on the right
            if (splitX < width) {
              ctx.beginPath()
              ctx.strokeStyle = mediaCard.trackColor.toString()
              ctx.lineWidth = 3
              ctx.lineCap = "round"
              ctx.moveTo(splitX + 4, cy)
              ctx.lineTo(width, cy)
              ctx.stroke()
            }

            // Played wavy track on the left
            if (splitX > 2) {
              ctx.beginPath()
              ctx.strokeStyle = mediaCard.activeColor.toString()
              ctx.lineWidth = 3
              ctx.lineCap = "round"
              ctx.lineJoin = "round"
              for (let x = 0; x <= splitX; x += 1.5) {
                const y = cy + amp * Math.sin((x / waveLen) * Math.PI * 2 + waveSeekBar.phase)
                if (x === 0) ctx.moveTo(x, y)
                else ctx.lineTo(x, y)
              }
              ctx.stroke()
            }
          }
        }

        // Vertical thumb indicator bar
        Rectangle {
          width: 4
          height: 18
          radius: 2
          color: mediaCard.activeColor
          anchors.verticalCenter: parent.verticalCenter
          x: Math.max(0, Math.min(waveSeekBar.width - width, seekRow.seekRatio * waveSeekBar.width - width / 2))
        }

        function seekFromX(posX: real): void {
          if (!MprisService.canSeek || MprisService.length <= 0) return
          const r = Math.max(0, Math.min(1, posX / waveSeekBar.width))
          MprisService.setPosition(r * MprisService.length)
          waveCanvas.requestPaint()
        }

        TapHandler {
          onTapped: (eventPoint) => waveSeekBar.seekFromX(eventPoint.position.x)
        }

        DragHandler {
          target: null
          xAxis.minimum: 0
          xAxis.maximum: waveSeekBar.width
          onCentroidChanged: {
            if (active) waveSeekBar.seekFromX(centroid.position.x)
          }
        }
      }

      Label {
        text: mediaCard.formatTime(MprisService.length)
        font.pixelSize: 12
        color: mediaCard.textSecondary
      }
    }

    // ── 3. Playback Controls Row ──
    RowLayout {
      Layout.alignment: Qt.AlignHCenter
      spacing: 24

      Icon {
        text: "skip_previous"
        font.pixelSize: 22
        color: mediaCard.textPrimary

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: MprisService.previous()
        }
      }

      Rectangle {
        Layout.preferredWidth: 56
        Layout.preferredHeight: 38
        radius: 13
        color: playMouse.containsMouse ? Qt.darker(mediaCard.activeColor, 1.08) : mediaCard.activeColor

        Icon {
          anchors.centerIn: parent
          text: MprisService.playing ? "pause" : "play_arrow"
          font.pixelSize: 22
          color: mediaCard.activeContentColor
        }

        MouseArea {
          id: playMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: MprisService.togglePlaying()
        }
      }

      Icon {
        text: "skip_next"
        font.pixelSize: 22
        color: mediaCard.textPrimary

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: MprisService.next()
        }
      }
    }
  }
}
