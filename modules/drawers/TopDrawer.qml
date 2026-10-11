import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland

import qs.common
import qs.components
import qs.services

PanelWindow {
  id: drawer

  property int drawerWidth: 800
  property int drawerHeight: 350
  property bool drawerHovered: true

  anchors {
    top: true
    left: true
    right: true
  }

  margins.top: Global.pillHeight

  exclusionMode: ExclusionMode.Ignore
  aboveWindows: false
  color: "transparent"
  implicitHeight: drawerHeight

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "media-drawer"

  onDrawerHoveredChanged: {
    if (drawerHovered) {
      hideTimer.stop()
    } else {
      hideTimer.restart()
    }
  }

  Timer {
    id: hideTimer
    interval: 250
    onTriggered: {}
  }

  // Ensure the drawer stays open if the mouse is currently over it
  readonly property bool open: drawerHovered || hideTimer.running || panelHoverHandler.hovered

  // flat rectangle mask that always covers the panel's current live position
  mask: Region {
    x: panel.x
    y: 0
    width: panel.width
    height: Math.max(0, panel.y + panel.height)
  }

  Item {
    id: panel
    width: drawer.drawerWidth
    anchors.horizontalCenter: parent.horizontalCenter
    height: drawer.drawerHeight

    y: drawer.open ? 0 : -drawer.drawerHeight
    Behavior on y {
      NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    HoverHandler {
      id: panelHoverHandler
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

        PathLine { x: Global.panelRadius; y: drawerHeight - Global.notchRadius }
        PathArc {
          x: Global.panelRadius + Global.notchRadius; y: drawerHeight
          radiusX: Global.notchRadius; radiusY: Global.notchRadius
          direction: PathArc.Counterclockwise
        }

        PathLine { x: drawerWidth - Global.panelRadius - Global.notchRadius; y: drawer.height }

        PathArc {
          x: drawerWidth - Global.panelRadius; y: drawerHeight - Global.notchRadius
          radiusX: Global.notchRadius; radiusY: Global.notchRadius
          direction: PathArc.Counterclockwise
        }
        PathLine { x: drawerWidth - Global.panelRadius; y: Global.panelRadius }

        PathArc {
          x: drawerWidth; y: 0
          radiusX: Global.panelRadius; radiusY: Global.panelRadius
        }
      }
    }

    RowLayout {
      id: contentLayout
      anchors.fill: parent
      anchors.leftMargin: Global.pad + Global.panelRadius
      anchors.rightMargin: Global.pad + Global.panelRadius
      anchors.topMargin: Global.pad + Global.panelRadius
      anchors.bottomMargin: Global.pad + Global.notchRadius
      spacing: Global.pad
      clip: true

      readonly property real halfWidth: (width - spacing * 2 - divider.width) / 2

      CalendarPanel {
        Layout.preferredWidth: contentLayout.halfWidth
        Layout.maximumWidth: contentLayout.halfWidth
        Layout.minimumWidth: 0
        Layout.fillHeight: true
      }

      Rectangle {
        id: divider
        Layout.preferredWidth: 1
        Layout.fillHeight: true
        color: Theme.m3surface_variant
      }

      MediaPanel {
        Layout.preferredWidth: contentLayout.halfWidth
        Layout.maximumWidth: contentLayout.halfWidth
        Layout.minimumWidth: 0
        Layout.fillHeight: true
      }
    }
  }
}
