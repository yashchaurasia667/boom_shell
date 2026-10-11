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
    // bottom: Global.panelRadius
  }

  exclusionMode: ExclusionMode.Ignore
  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "notification-popup"

  color: "transparent"
  implicitWidth: toastWidth + Global.panelRadius + Global.pad
  implicitHeight: column.implicitHeight === 0 ? 0 : column.implicitHeight + Global.panelRadius + Global.pad

  // click-through everywhere except where toasts actually are
  mask: Region {
    item: column
  }

  // framed shape
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      startX: 0; startY: 0
      fillRule: ShapePath.OddEvenFill
      fillColor: Theme.m3surface
      // fillColor: "white"
      strokeColor: "transparent"

      PathArc {
        x: Global.panelRadius; y: Global.panelRadius
        radiusX: Global.panelRadius; radiusY: Global.panelRadius
      }
      PathLine { x: Global.panelRadius; y: popup.height - 2*Global.panelRadius }
      PathArc {
        x: 2 * Global.panelRadius; y: popup.height-Global.panelRadius
        radiusX: Global.panelRadius; radiusY: Global.panelRadius
        direction: PathArc.Counterclockwise
      }
      PathLine { x: popup.width - Global.panelRadius; y: popup.height-Global.panelRadius }
      PathArc {
        x: popup.width; y: popup.height
        radiusX: Global.panelRadius; radiusY: Global.panelRadius
      }
      PathLine { x: popup.width; y: 0 }
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
