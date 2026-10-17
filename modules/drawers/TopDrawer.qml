import QtQuick
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
  property bool drawerHovered: false
  property bool _ready: false
  signal dismissed()

  Component.onCompleted: Qt.callLater(() => { drawer._ready = true })

  anchors {
    top: true
    left: true
    right: true
  }

  margins.top: Global.pillHeight

  exclusionMode: ExclusionMode.Ignore
  aboveWindows: false
  color: "transparent"
  // Extra headroom so the elastic spring overshoot on height is never clipped by the window
  implicitHeight: drawerHeight + 100

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "media-drawer"

  readonly property bool anyHovered: drawerHovered || panelHoverHandler.hovered

  onAnyHoveredChanged: {
    if (anyHovered) {
      hideTimer.stop()
      closeDelay.stop()
    } else {
      hideTimer.restart()
    }
  }

  Timer {
    id: hideTimer
    interval: 250
    onTriggered: closeDelay.restart()
  }

  Timer {
    id: closeDelay
    interval: Global.dur.normal
    onTriggered: {
      if (!drawer.open) drawer.dismissed()
    }
  }

  // Ensure the drawer stays open if the mouse is currently over it or within grace period
  readonly property bool open: anyHovered || hideTimer.running

  // flat rectangle mask that always covers the panel's current live size
  mask: Region {
    x: panel.x
    y: 0
    width: panel.width
    height: Math.max(0, panel.height)
  }

  Item {
    id: panel
    clip: true
    width: drawer.drawerWidth
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    height: (drawer.open && drawer._ready) ? drawer.drawerHeight : 0

    Behavior on height {
      Anim {}
    }

    HoverHandler {
      id: panelHoverHandler
    }

    NotchShape {
      anchors.fill: parent
      edge: "top"
    }

    RowLayout {
      id: contentLayout
      width: drawer.drawerWidth - 2 * (Global.pad + Global.panelRadius)
      height: drawer.drawerHeight - (Global.pad + Global.panelRadius) - (Global.pad + Global.notchRadius)
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
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
