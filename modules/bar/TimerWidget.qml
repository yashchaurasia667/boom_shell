import QtQuick
import QtQuick.Shapes

import qs.common
import qs.components
import qs.services

// Shows a ring that drains as the timer counts down.
// Expands to reveal the remaining time while `expanded` is true.
Item {
  id: root

  property bool expanded: false
  readonly property bool active: !TimerService.isIdle
  readonly property int ringSize: 18

  readonly property int remainingSeconds: Math.ceil(TimerService.remainingMs / 1000)
  readonly property color accent: TimerService.isFinished ? Theme.m3error : Theme.m3primary

  readonly property bool showText: expanded && active
  readonly property real textWidth: timeLabel.implicitWidth

  implicitWidth: active ? ringSize + (showText ? 6 + textWidth : 0) : 0
  implicitHeight: ringSize
  opacity: active ? (TimerService.isPaused ? 0.6 : 1) : 0
  clip: true

  Behavior on implicitWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
  Behavior on opacity { NumberAnimation { duration: 180 } }

  HoverHandler { id: selfHover; onHoveredChanged: root.hoveredSelf = hovered }
  property bool hoveredSelf: false

  Shape {
    id: ring
    width: root.ringSize
    height: root.ringSize
    anchors.verticalCenter: parent.verticalCenter
    preferredRendererType: Shape.CurveRenderer

    readonly property real inset: 2
    readonly property real r: (root.ringSize - 2 * inset) / 2

    // track
    ShapePath {
      strokeWidth: 2.5
      strokeColor: Theme.m3surface_container_highest
      fillColor: "transparent"
      PathAngleArc {
        centerX: root.ringSize / 2; centerY: root.ringSize / 2
        radiusX: ring.r; radiusY: ring.r
        startAngle: -90; sweepAngle: 360
      }
    }

    // remaining time
    ShapePath {
      strokeWidth: 2.5
      strokeColor: root.accent
      fillColor: "transparent"
      capStyle: ShapePath.RoundCap
      PathAngleArc {
        centerX: root.ringSize / 2; centerY: root.ringSize / 2
        radiusX: ring.r; radiusY: ring.r
        startAngle: -90
        sweepAngle: TimerService.isFinished ? 360 : 360 * TimerService.progress
      }
    }

    // gentle pulse while ringing
    SequentialAnimation on opacity {
      running: TimerService.isFinished
      loops: Animation.Infinite
      onRunningChanged: if (!running) ring.opacity = 1
      NumberAnimation { to: 0.35; duration: 450 }
      NumberAnimation { to: 1; duration: 450 }
    }
  }

  Label {
    id: timeLabel
    anchors.left: ring.right
    anchors.leftMargin: 6
    anchors.verticalCenter: parent.verticalCenter
    text: TimerService.formatSeconds(root.remainingSeconds)
    color: root.accent
    font.bold: true
    font.pixelSize: 13
    opacity: root.showText ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: 150 } }
  }
}
