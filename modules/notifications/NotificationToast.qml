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

  // Fixed-size window (full height, click-through via the mask below). Resizing a layer-shell
  // surface every animation frame causes flicker, so the window never changes size.
  anchors {
    top: true
    right: true
    bottom: true
  }

  margins {
    top: Global.pillHeight
  }

  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "notification-popup"

  color: "transparent"
  implicitWidth: toastWidth + Global.panelRadius + Global.pad

  // click-through everywhere except where toasts actually are
  mask: Region {
    item: frameItem
  }

  Item {
    id: frameItem
    anchors.top: parent.top
    anchors.right: parent.right
    width: popup.implicitWidth
    // the frame's extra padding eases in/out with the content, so it never pops when the last toast leaves
    height: column.implicitHeight
      + (Global.panelRadius + Global.pad - 8) * Math.max(0, Math.min(1, column.implicitHeight / 40))

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
      spacing: 0   // each tile carries its own bottom gap

      Repeater {
        model: NotificationService.notifications

        delegate: NotificationTile {}
      }
    }
  }
}
