import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.common

import "bar"
import "notifications"
import "drawers"

Scope {
  id: root
  required property var modelData
  property bool showNotifications: false
  property bool isAnyHovered: bar.controlCenterVisible || controlCenter.isHovered

  onIsAnyHoveredChanged: {
    if (isAnyHovered) {
      hideTimer.stop()
      root.showNotifications = true
    } else {
      hideTimer.restart()
    }
  }

  Timer {
    id: hideTimer
    interval: 200
    onTriggered: root.showNotifications = false
  }
 
  Exclusion { screen: root.modelData; edge: "top"; size: Global.reserveTop }
  Exclusion { screen: root.modelData; edge: "bottom"; size: Global.border }
  Exclusion { screen: root.modelData; edge: "left"; size: Global.border }
  Exclusion { screen: root.modelData; edge: "right"; size: Global.border }

  Bar { 
    id: bar
    screen: root.modelData 
  }

  NotificationToast {}
  QuickSliders {}
  ControlCenter {
    id: controlCenter
    screen: root.modelData
    open: root.showNotifications
  }

}

