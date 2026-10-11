import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland

import qs.common
import "../drawers/"

PanelWindow {
  id: frame

  property real thickness: Global.border        // border stroke thickness
  property real radius: Global.borderRadius         // corner radius
  property color borderColor: Theme.m3surface
  property bool clockHovered: clockHandler.hovered

  readonly property bool controlCenterVisible: hotCornerArea.containsMouse

  anchors {
    top: true
    bottom: true
    left: true
    right: true

    // leftMargin: Global.pad
    // marginRight: Global.pad
  }

  exclusionMode: ExclusionMode.Ignore
  aboveWindows: false
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "frame"

  // click-through: nothing in this window should intercept input
  mask: Region {
    // outer: whole window is "solid" (blocks input) by default
    x: 0; y: 0
    width: frame.width
    height: frame.height

    // inner: subtract the hole so input passes through the center
    Region {
      x: outline.t
      y: Global.reserveTop
      width: frame.width - outline.t * 2
      height: frame.height - outline.t - Global.reserveTop
      intersection: Intersection.Subtract
    }

    // hot corner region
    Region {
      x: frame.width - 20
      y: frame.height - 20
      width: 20
      height: 20
    }
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer

    ShapePath {
      id: outline

      readonly property real t: frame.thickness
      readonly property real r: frame.radius
      readonly property real w: frame.width
      readonly property real h: frame.height

      fillRule: ShapePath.OddEvenFill
      fillColor: frame.borderColor
      strokeWidth: -1
      //
      // outer rect (full window)
      startX: 0; startY: 0
      PathLine { x: outline.w; y: 0 }
      PathLine { x: outline.w; y: outline.h }
      PathLine { x: 0; y: outline.h }
      PathLine { x: 0; y: 0 }

      // inner rounded rect (the hole) — carved out by OddEvenFill
      PathMove { x: outline.t + outline.r; y: Global.reserveTop }
      PathLine { x: outline.w - outline.t - outline.r; y: Global.reserveTop }
      PathArc { x: outline.w - outline.t; y: Global.reserveTop + outline.r; radiusX: outline.r; radiusY: outline.r }
      PathLine { x: outline.w - outline.t; y: outline.h - outline.t - outline.r }
      PathArc { x: outline.w - outline.t - outline.r; y: outline.h - outline.t; radiusX: outline.r; radiusY: outline.r }
      PathLine { x: outline.t + outline.r; y: outline.h - outline.t }
      PathArc { x: outline.t; y: outline.h - outline.t - outline.r; radiusX: outline.r; radiusY: outline.r }
      PathLine { x: outline.t; y: Global.reserveTop + outline.r }
      PathArc { x: outline.t + outline.r; y: Global.reserveTop; radiusX: outline.r; radiusY: outline.r }
    }
  }

  Item {
    anchors.top: parent.top
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.leftMargin: Global.pad
    anchors.rightMargin: Global.pad

    height: Global.pillHeight

    Workspaces {
      id: workspaces
      anchors.left: parent.left
      anchors.verticalCenter: parent.verticalCenter
    }

    Clock {
      id: clock
      anchors.centerIn: parent

      HoverHandler {
        id: clockHandler
      }
    }

    RowLayout {
      id: rightGroup
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      spacing: 12

      SystemTray {}
      CpuInfo {}
      Volume {}
      Battery {}
    }
  }

  TopDrawer { 
    screen: root.modelData
    drawerHovered: clockHovered
  }

  // hot corner
  Rectangle {
    width: 20
    height: 20
    color: "transparent"

    anchors {
      bottom: parent.bottom
      right: parent.right
    }

    MouseArea {
      id: hotCornerArea

      anchors.fill: parent
      hoverEnabled: true
    }
  }
}
