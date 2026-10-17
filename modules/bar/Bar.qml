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
  property real radius: Global.borderRadius     // corner radius
  property color borderColor: Theme.m3surface
  property bool clockHovered: clock.hovered

  readonly property bool controlCenterVisible: hotCornerArea.containsMouse
  readonly property bool slidersZoneHovered: slidersTriggerHandler.hovered

  // Match QuickSliders dimensions for the right-edge trigger strip
  readonly property int slidersTriggerWidth: Global.border + 4
  readonly property int slidersTriggerHeight: 150 * 2 + 12 + 2 * (Global.pad + Global.panelRadius)

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  exclusionMode: ExclusionMode.Ignore
  aboveWindows: false
  color: "transparent"

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "frame"

  onClockHoveredChanged: {
    if (clockHovered) topDrawerLoader.active = true
  }

  // click-through: nothing in this window should intercept input except top bar, right slider zone, and hot corner
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

    // right-edge quick sliders hover zone
    Region {
      x: frame.width - frame.slidersTriggerWidth
      y: Math.round((frame.height - frame.slidersTriggerHeight) / 2)
      width: frame.slidersTriggerWidth
      height: frame.slidersTriggerHeight
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

      // HoverHandler {
      //   id: clockHandler
      // }
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

  Loader {
    id: topDrawerLoader
    active: false
    sourceComponent: TopDrawer {
      screen: frame.screen
      drawerHovered: frame.clockHovered
      onDismissed: topDrawerLoader.active = false
    }
  }

  // right-edge trigger zone for QuickSliders
  Item {
    width: frame.slidersTriggerWidth
    height: frame.slidersTriggerHeight
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter

    HoverHandler {
      id: slidersTriggerHandler
    }
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
