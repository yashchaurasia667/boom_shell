import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland
import Quickshell.Services.Notifications

import qs.common
import qs.components
import qs.services

PanelWindow {
  id: popup

  property int toastWidth: 340

  anchors {
    top: true
    right: true
  }

  margins {
    top: Global.pillHeight
  }

  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "notification-popup"

  color: "transparent"
  implicitWidth: toastWidth + Global.panelRadius + Global.pad
  // Extra vertical headroom so elastic height overshoot is never clipped by the window
  implicitHeight: Math.max(1, column.implicitHeight + Global.panelRadius + Global.pad + 60)

  // click-through everywhere except where toasts actually are
  mask: Region {
    item: frameItem
  }

  Item {
    id: frameItem
    anchors.top: parent.top
    anchors.right: parent.right
    width: popup.implicitWidth
    height: column.implicitHeight <= 0 ? 0 : column.implicitHeight + Global.panelRadius + Global.pad

    // framed shape
    Shape {
      id: toastShape
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer

      readonly property real _w: Math.max(0, frameItem.width)
      readonly property real _h: Math.max(0, frameItem.height)
      readonly property real _r: Math.min(Global.panelRadius, _w / 3, _h / 2)

      ShapePath {
        startX: 0; startY: 0
        fillRule: ShapePath.OddEvenFill
        fillColor: Theme.m3surface
        strokeColor: "transparent"

        PathArc {
          x: toastShape._r; y: toastShape._r
          radiusX: toastShape._r; radiusY: toastShape._r
        }
        PathLine { x: toastShape._r; y: toastShape._h - 2 * toastShape._r }
        PathArc {
          x: 2 * toastShape._r; y: toastShape._h - toastShape._r
          radiusX: toastShape._r; radiusY: toastShape._r
          direction: PathArc.Counterclockwise
        }
        PathLine { x: toastShape._w - toastShape._r; y: toastShape._h - toastShape._r }
        PathArc {
          x: toastShape._w; y: toastShape._h
          radiusX: toastShape._r; radiusY: toastShape._r
        }
        PathLine { x: toastShape._w; y: 0 }
      }
    }

    ColumnLayout {
      id: column
      width: popup.toastWidth
      anchors.right: parent.right
      anchors.top: parent.top
      spacing: 8

      Repeater {
        model: NotificationService.notifications

        delegate: NotificationTile {}
      }
    }
  }
}
