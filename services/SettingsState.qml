pragma Singleton

import QtQuick
import Quickshell

// Requests from TopDrawer, IPC, or keybinds to open/close/toggle the Settings App.
Singleton {
  signal toggleRequested()
  signal showRequested()
  signal hideRequested()
}
