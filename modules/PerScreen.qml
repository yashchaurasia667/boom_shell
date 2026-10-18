import QtQuick
import Quickshell
import Quickshell.Wayland

import Quickshell.Hyprland

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
  readonly property bool isAnyHovered: (Global.controlCenterEnabled && bar.controlCenterVisible) || (controlCenterLoader.item?.isHovered ?? false)

  // opened through IPC: stays open until toggled again, or until the pointer has entered and left it
  property bool pinnedOpen: false
  property bool _pinnedHoverSeen: false
  readonly property bool controlCenterOpen: showNotifications || pinnedOpen

  readonly property bool isFocusedScreen: Hyprland.focusedMonitor
    ? Hyprland.focusedMonitor.name === modelData.name
    : modelData === Quickshell.screens[0]

  function openControlCenter(): void {
    hideTimer.stop()
    controlCenterLoader.active = true
    root._pinnedHoverSeen = false
    root.pinnedOpen = true
  }

  function closeControlCenter(): void {
    root.pinnedOpen = false
    root.showNotifications = false
  }

  onIsAnyHoveredChanged: {
    if (isAnyHovered) {
      hideTimer.stop()
      controlCenterLoader.active = true
      root.showNotifications = true
      if (root.pinnedOpen) root._pinnedHoverSeen = true
    } else {
      hideTimer.restart()
      if (root.pinnedOpen && root._pinnedHoverSeen) root.pinnedOpen = false
    }
  }

  Connections {
    target: ControlCenterState

    function onToggleRequested(): void {
      if (!root.isFocusedScreen) return
      if (root.controlCenterOpen) root.closeControlCenter()
      else root.openControlCenter()
    }

    function onShowRequested(): void {
      if (root.isFocusedScreen && !root.controlCenterOpen) root.openControlCenter()
    }

    function onHideRequested(): void {
      if (root.isFocusedScreen) root.closeControlCenter()
    }
  }

  Timer {
    id: hideTimer
    interval: Global.controlCenterHideDelay
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
      if (slidersZoneHovered && Global.quickSlidersEnabled) quickSlidersLoader.active = true
    }
  }

  Loader {
    active: Global.desktopClockEnabled
    sourceComponent: DesktopClock {
      screen: root.modelData
    }
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
      open: root.controlCenterOpen
      onDismissed: controlCenterLoader.active = false
    }
  }
}
