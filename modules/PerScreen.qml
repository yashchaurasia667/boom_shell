import QtQuick
import Quickshell
import Quickshell.Wayland

import qs.common
import qs.services
import qs.widgets

import "bar"
import "notifications"
import "drawers"

Scope {
  id: root
  required property var modelData
  property bool showNotifications: false
  readonly property bool isAnyHovered: bar.controlCenterVisible || (controlCenterLoader.item?.isHovered ?? false)

  onIsAnyHoveredChanged: {
    if (isAnyHovered) {
      hideTimer.stop()
      controlCenterLoader.active = true
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
    onSlidersZoneHoveredChanged: {
      if (slidersZoneHovered) quickSlidersLoader.active = true
    }
  }

  DesktopClock {
    screen: root.modelData
  }

  // Only allocate NotificationToast PanelWindow when there are active notifications
  Loader {
    active: NotificationService.hasNotifications
    sourceComponent: NotificationToast {
      screen: root.modelData
    }
  }

  // Lazy-load QuickSliders only when right-edge hover zone is triggered
  Loader {
    id: quickSlidersLoader
    active: false
    sourceComponent: QuickSliders {
      screen: root.modelData
      triggerHovered: bar.slidersZoneHovered
      onDismissed: quickSlidersLoader.active = false
    }
  }

  // Lazy-load ControlCenter only when bottom-right hot corner is hovered
  Loader {
    id: controlCenterLoader
    active: false
    sourceComponent: ControlCenter {
      screen: root.modelData
      open: root.showNotifications
      onDismissed: controlCenterLoader.active = false
    }
  }
}
