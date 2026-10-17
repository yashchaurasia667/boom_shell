import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

import qs.common
import qs.components
import qs.services

import "notifications"
import "quicksettings"

PanelWindow {
  id: controlCenter
  readonly property bool isHovered: hoverHandler.hovered

  property bool open: false
  property bool _ready: false
  readonly property int panelWidth: 400 + Global.panelRadius + Global.pad
  signal dismissed()

  Component.onCompleted: Qt.callLater(() => { controlCenter._ready = true })

  anchors {
    top: true
    bottom: true
    right: true
  }

  aboveWindows: false
  exclusiveZone: 0

  // Extra width headroom so the elastic spring overshoot on width is never clipped by the window
  implicitWidth: panelWidth + 100
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Top

  visible: open || hideDelay.running

  mask: Region {
    x: panel.x
    y: 0
    width: Math.max(0, panel.width)
    height: controlCenter.height
  }

  onOpenChanged: {
    if (open) {
      hideDelay.stop()
    } else {
      hideDelay.restart()
    }
  }

  Timer {
    id: hideDelay
    interval: Global.dur.normal   // must match the Behavior's duration
    onTriggered: {
      if (!controlCenter.open) controlCenter.dismissed()
    }
  }

  Item {
    id: panel
    clip: true
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    anchors.right: parent.right
    width: (controlCenter.open && controlCenter._ready) ? controlCenter.panelWidth : 0

    Behavior on width {
      Anim {}
    }

    HoverHandler {
      id: hoverHandler
    }

    Shape {
      id: bgShape
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer

      readonly property real _w: Math.max(0, panel.width)
      readonly property real _h: Math.max(0, panel.height)
      readonly property real _r: Math.min(Global.panelRadius, _w, _h / 2)

      ShapePath {
        startX: 0; startY: 0
        fillRule: ShapePath.OddEvenFill
        fillColor: Theme.m3surface
        strokeColor: "transparent"

        PathArc {
          x: bgShape._r; y: bgShape._r
          radiusX: bgShape._r; radiusY: bgShape._r
        }

        PathLine { x: bgShape._r; y: bgShape._h - bgShape._r }

        PathArc {
          x: 0; y: bgShape._h
          radiusX: bgShape._r; radiusY: bgShape._r
        }

        PathLine { x: bgShape._w; y: bgShape._h }
        PathLine { x: bgShape._w; y: 0 }
      }
    }

    ColumnLayout {
      width: controlCenter.panelWidth - Global.panelRadius - 3 * Global.pad
      anchors.left: parent.left
      anchors.leftMargin: Global.panelRadius + 2 * Global.pad
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.topMargin: Global.pad
      anchors.bottomMargin: Global.panelRadius
      spacing: 8

      NotificationCenter {
        Layout.fillWidth: true
        Layout.fillHeight: true   // grows to fill available space, pushing QuickSettings down
      }

      QuickSettings {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignBottom   // stays pinned to the bottom edge
      }
    }
  }
}
