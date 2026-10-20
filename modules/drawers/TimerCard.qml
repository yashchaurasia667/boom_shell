import QtQuick
import QtQuick.Layouts

import qs.common
import qs.components
import qs.services

Rectangle {
  id: root

  color: Theme.m3surface_container_highest

  readonly property int hours: Math.floor(TimerService.durationSeconds / 3600)
  readonly property int minutes: Math.floor((TimerService.durationSeconds % 3600) / 60)
  readonly property int seconds: TimerService.durationSeconds % 60

  function setHMS(h: int, m: int, s: int): void {
    TimerService.setDuration(h * 3600 + m * 60 + s)
  }

  // ── small reusable pieces ──

  // One wheel of the HH : MM : SS picker
  component Spinner: Item {
    id: spin
    property int value: 0
    property int maxValue: 59
    signal edited(int v)

    implicitWidth: 56
    implicitHeight: 110

    function bump(delta: int): void {
      const range = maxValue + 1
      edited(((value + delta) % range + range) % range)
    }

    WheelHandler {
      onWheel: (e) => spin.bump(e.angleDelta.y > 0 ? 1 : -1)
    }

    ColumnLayout {
      anchors.fill: parent
      spacing: 0

      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 32
        Layout.preferredHeight: 28
        radius: 14
        color: upMouse.containsMouse ? Theme.m3surface_bright : "transparent"
        Icon {
          anchors.centerIn: parent
          text: "keyboard_arrow_up"
          font.pixelSize: 22
          color: Theme.m3on_surface_variant
        }
        MouseArea {
          id: upMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: spin.bump(1)
        }
      }

      Label {
        Layout.alignment: Qt.AlignHCenter
        Layout.fillHeight: true
        verticalAlignment: Text.AlignVCenter
        text: (spin.value < 10 ? "0" : "") + spin.value
        font.pixelSize: 34
        font.bold: true
        color: Theme.m3on_surface
      }

      Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 32
        Layout.preferredHeight: 28
        radius: 14
        color: downMouse.containsMouse ? Theme.m3surface_bright : "transparent"
        Icon {
          anchors.centerIn: parent
          text: "keyboard_arrow_down"
          font.pixelSize: 22
          color: Theme.m3on_surface_variant
        }
        MouseArea {
          id: downMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: spin.bump(-1)
        }
      }
    }
  }

  // Pill button (primary = filled, otherwise tonal)
  component PillButton: Rectangle {
    id: btn
    property string icon: ""
    property string text: ""
    property bool primary: true
    property bool enabled: true
    signal clicked()

    Layout.fillWidth: true
    Layout.preferredHeight: 42
    radius: 21
    opacity: enabled ? 1 : 0.4
    color: primary
      ? Theme.m3primary
      : (btnMouse.containsMouse ? Theme.m3surface_bright : Theme.m3surface_container_high)

    Row {
      anchors.centerIn: parent
      spacing: 6
      Icon {
        anchors.verticalCenter: parent.verticalCenter
        text: btn.icon
        font.pixelSize: 20
        color: btn.primary ? Theme.m3on_primary : Theme.m3on_surface
      }
      Label {
        anchors.verticalCenter: parent.verticalCenter
        text: btn.text
        font.pixelSize: 14
        font.bold: true
        color: btn.primary ? Theme.m3on_primary : Theme.m3on_surface
      }
    }

    MouseArea {
      id: btnMouse
      anchors.fill: parent
      hoverEnabled: true
      enabled: btn.enabled
      cursorShape: Qt.PointingHandCursor
      onClicked: btn.clicked()
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 16
    spacing: 12

    RowLayout {
      Layout.fillWidth: true
      spacing: 6
      Icon {
        text: "timer"
        font.pixelSize: 18
        color: Theme.m3on_surface_variant
      }
      Label {
        text: TimerService.isFinished ? "Time's up" : "Timer"
        font.pixelSize: 14
        color: TimerService.isFinished ? Theme.m3error : Theme.m3on_surface_variant
      }
    }

    // ── Middle area: picker (idle) or progress ring (running/paused/finished) ──
    Item {
      Layout.fillWidth: true
      Layout.fillHeight: true

      // Idle: set the time
      ColumnLayout {
        anchors.centerIn: parent
        spacing: 14
        visible: TimerService.isIdle

        Row {
          Layout.alignment: Qt.AlignHCenter
          spacing: 2

          Spinner {
            maxValue: 99
            value: root.hours
            onEdited: (v) => root.setHMS(v, root.minutes, root.seconds)
          }
          Label {
            anchors.verticalCenter: parent.verticalCenter
            text: ":"
            font.pixelSize: 30
            font.bold: true
            color: Theme.m3on_surface_variant
          }
          Spinner {
            value: root.minutes
            onEdited: (v) => root.setHMS(root.hours, v, root.seconds)
          }
          Label {
            anchors.verticalCenter: parent.verticalCenter
            text: ":"
            font.pixelSize: 30
            font.bold: true
            color: Theme.m3on_surface_variant
          }
          Spinner {
            value: root.seconds
            onEdited: (v) => root.setHMS(root.hours, root.minutes, v)
          }
        }

        // Quick presets
        Row {
          Layout.alignment: Qt.AlignHCenter
          spacing: 6

          Repeater {
            model: [1, 5, 10, 15, 30]
            delegate: Rectangle {
              required property int modelData
              readonly property bool selected: TimerService.durationSeconds === modelData * 60
              width: 44
              height: 28
              radius: 14
              color: selected
                ? Theme.m3secondary_container
                : (presetMouse.containsMouse ? Theme.m3surface_bright : Theme.m3surface_container_high)

              Label {
                anchors.centerIn: parent
                text: modelData + "m"
                font.pixelSize: 12
                color: parent.selected ? Theme.m3on_secondary_container : Theme.m3on_surface_variant
              }
              MouseArea {
                id: presetMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: TimerService.setDuration(modelData * 60)
              }
            }
          }
        }
      }

      // Running / paused / finished: ring + remaining time
      Item {
        id: ringArea
        anchors.fill: parent
        visible: !TimerService.isIdle

        readonly property real size: Math.max(60, Math.min(width, height) - 4)

        Canvas {
          id: ring
          anchors.centerIn: parent
          width: ringArea.size
          height: ringArea.size

          readonly property real progress: TimerService.progress
          readonly property color trackCol: Theme.m3outline_variant
          readonly property color fillCol: TimerService.isFinished ? Theme.m3error : Theme.m3primary

          onProgressChanged: requestPaint()
          onTrackColChanged: requestPaint()
          onFillColChanged: requestPaint()
          onWidthChanged: requestPaint()

          onPaint: {
            const ctx = getContext("2d")
            ctx.reset()
            const lw = 9
            const r = (width - lw) / 2
            const cx = width / 2
            const cy = height / 2
            ctx.lineWidth = lw
            ctx.lineCap = "round"

            ctx.strokeStyle = trackCol
            ctx.beginPath()
            ctx.arc(cx, cy, r, 0, Math.PI * 2)
            ctx.stroke()

            const p = TimerService.isFinished ? 1 : progress
            if (p > 0.001) {
              ctx.strokeStyle = fillCol
              ctx.beginPath()
              ctx.arc(cx, cy, r, -Math.PI / 2, -Math.PI / 2 + Math.PI * 2 * p)
              ctx.stroke()
            }
          }
        }

        ColumnLayout {
          anchors.centerIn: parent
          spacing: 2

          Label {
            Layout.alignment: Qt.AlignHCenter
            text: TimerService.formatSeconds(Math.ceil(TimerService.remainingMs / 1000))
            font.pixelSize: 36
            font.bold: true
            color: TimerService.isFinished ? Theme.m3error : Theme.m3on_surface
            opacity: TimerService.isPaused ? 0.6 : 1
          }
          Label {
            Layout.alignment: Qt.AlignHCenter
            text: TimerService.isPaused ? "Paused"
              : (TimerService.isFinished ? "Finished" : "of " + TimerService.formatSeconds(TimerService.durationSeconds))
            font.pixelSize: 12
            color: Theme.m3on_surface_variant
          }
        }
      }
    }

    // ── Controls ──
    RowLayout {
      Layout.fillWidth: true
      spacing: 8

      PillButton {
        visible: TimerService.isIdle
        icon: "play_arrow"
        text: "Start"
        enabled: TimerService.durationSeconds > 0
        onClicked: TimerService.start()
      }

      PillButton {
        visible: TimerService.isRunning
        icon: "pause"
        text: "Pause"
        onClicked: TimerService.pause()
      }

      PillButton {
        visible: TimerService.isPaused
        icon: "play_arrow"
        text: "Resume"
        onClicked: TimerService.resume()
      }

      PillButton {
        visible: TimerService.isRunning || TimerService.isPaused
        primary: false
        icon: "restart_alt"
        text: "Reset"
        onClicked: TimerService.reset()
      }

      PillButton {
        visible: TimerService.isFinished
        icon: "notifications_off"
        text: "Dismiss"
        onClicked: TimerService.reset()
      }
    }
  }
}
