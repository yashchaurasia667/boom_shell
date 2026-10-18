//@ pragma UseQApplication
//@ pragma DefaultEnv QS_DROP_EXPENSIVE_FONTS=1
//@ pragma DefaultEnv QSG_RENDER_LOOP=threaded
//@ pragma DefaultEnv QT_QUICK_FLICKABLE_WHEEL_DECELERATION=10000
import Quickshell
import Quickshell.Io
import QtQuick

import qs.components
import qs.modules
import qs.services
import qs.widgets

import "modules/bar"

ShellRoot {
  id: root

  Variants {
    model: Quickshell.screens
    PerScreen {}
  }

  TodoList {}

  // Lazy-loaded AppLauncher: unloaded from RAM when dismissed
  Loader {
    id: launcherLoader
    active: false
    sourceComponent: AppLauncher {
      onDismissed: launcherLoader.active = false
    }
  }

  IpcHandler {
    target: "launcher"
    function toggle(): void {
      if (launcherLoader.active && launcherLoader.item.open) {
        launcherLoader.item.hide()
      } else {
        launcherLoader.active = true
        launcherLoader.item.show()
      }
    }
    function show(): void {
      launcherLoader.active = true
      launcherLoader.item.show()
    }
    function hide(): void {
      if (launcherLoader.active) launcherLoader.item.hide()
    }
  }

  // Control center (notifications + quick settings) on the focused screen
  //   qs ipc call controlcenter toggle|show|hide
  IpcHandler {
    target: "controlcenter"
    function toggle(): void { ControlCenterState.toggleRequested() }
    function show(): void { ControlCenterState.showRequested() }
    function hide(): void { ControlCenterState.hideRequested() }
  }

  // Notifications
  //   qs ipc call notifications toggleDnd|enableDnd|disableDnd|clear|dnd
  IpcHandler {
    target: "notifications"
    function toggleDnd(): void { NotificationService.toggleDoNotDisturb() }
    function enableDnd(): void { NotificationService.setDoNotDisturb(true) }
    function disableDnd(): void { NotificationService.setDoNotDisturb(false) }
    function clear(): void { NotificationService.clearHistory() }
    function dnd(): bool { return NotificationService.doNotDisturb }
  }

  // Lazy-loaded Clipboard: unloaded from RAM when dismissed
  Loader {
    id: clipboardLoader
    active: false
    sourceComponent: Clipboard {
      onDismissed: clipboardLoader.active = false
    }
  }

  IpcHandler {
    target: "clipboard"
    function toggle(): void {
      if (clipboardLoader.active && clipboardLoader.item.open) {
        clipboardLoader.item.hide()
      } else {
        clipboardLoader.active = true
        clipboardLoader.item.show()
      }
    }
    function show(): void {
      clipboardLoader.active = true
      clipboardLoader.item.show()
    }
    function hide(): void {
      if (clipboardLoader.active) clipboardLoader.item.hide()
    }
  }

  // Lazy-loaded WallpaperSwitcher: unloaded from RAM when dismissed
  Loader {
    id: wallpaperLoader
    active: false
    sourceComponent: WallpaperSwitcher {
      onDismissed: wallpaperLoader.active = false
    }
  }

  IpcHandler {
    target: "wallpaper"
    function toggle(): void {
      if (wallpaperLoader.active && wallpaperLoader.item.open) {
        wallpaperLoader.item.hide()
      } else {
        wallpaperLoader.active = true
        wallpaperLoader.item.show()
      }
    }
    function show(): void {
      wallpaperLoader.active = true
      wallpaperLoader.item.show()
    }
    function hide(): void {
      if (wallpaperLoader.active) wallpaperLoader.item.hide()
    }
  }

  // Lazy-loaded PowerMenu: unloaded from RAM when dismissed
  Loader {
    id: powerMenuLoader
    active: false
    sourceComponent: PowerMenu {
      onDismissed: powerMenuLoader.active = false
    }
  }

  IpcHandler {
    target: "powermenu"
    function toggle(): void {
      if (powerMenuLoader.active && powerMenuLoader.item.open) {
        powerMenuLoader.item.hide()
      } else {
        powerMenuLoader.active = true
        powerMenuLoader.item.show()
      }
    }
    function show(): void {
      powerMenuLoader.active = true
      powerMenuLoader.item.show()
    }
    function hide(): void {
      if (powerMenuLoader.active) powerMenuLoader.item.hide()
    }
  }
}
