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

  anchors {
    top: true
    bottom: true
    right: true
  }

  aboveWindows: false
  exclusiveZone: 0

  implicitWidth: 400 + Global.panelRadius + Global.pad
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Top

  margins.right: open ? 0 : -controlCenter.implicitWidth
  Behavior on margins.right {
    NumberAnimation { duration: 120; easing.type: Easing.OutCubic }
  }

  // window stays alive while sliding out; only truly hides once off-screen
  visible: open || hideDelay.running

  onOpenChanged: {
    if (!open) hideDelay.restart()
  }

  Timer {
    id: hideDelay
    interval: 120   // must match the Behavior's duration above
    onTriggered: {} // visible binding re-evaluates on its own once this stops running
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      startX: 0; startY: 0
      fillRule: ShapePath.OddEvenFill
      fillColor: Theme.m3surface
      strokeColor: "transparent"

      PathArc {
        x: Global.panelRadius; y: Global.panelRadius
        radiusX: Global.panelRadius; radiusY: Global.panelRadius
      }

      PathLine { x: Global.panelRadius; y: controlCenter.height - Global.panelRadius }

      PathArc {
        x: 0; y: controlCenter.height
        radiusX: Global.panelRadius; radiusY: Global.panelRadius
      }

      PathLine { x: controlCenter.width; y: controlCenter.height }
      PathLine { x: controlCenter.width; y: 0 }
    }
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.leftMargin: Global.panelRadius + 2*Global.pad
    anchors.rightMargin: Global.pad
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

  HoverHandler {
    id: hoverHandler
  }
}
