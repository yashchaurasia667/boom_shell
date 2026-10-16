//@ pragma UseQApplication
import Quickshell
import Quickshell.Io
import QtQuick

import qs.components
import qs.modules
import qs.widgets

import "modules/bar"

ShellRoot {
  id: root
  Variants {
    model: Quickshell.screens
    PerScreen {}
  }
  TodoList {}
  AppLauncher {}
  Clipboard {}
  Loader {
    id: wallpaperLoader
    active: false

    sourceComponent: WallpaperSwitcher {
      onClosed: wallpaperLoader.active = false
    }
  }

  IpcHandler {
    target: "wallpaper"
    function toggle(): void {
      if (wallpaperLoader.active) {
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

  PowerMenu {}
}
