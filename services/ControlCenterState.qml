pragma Singleton

import QtQuick
import Quickshell

// Requests from outside the per-screen control center (IPC / keybinds).
// The control center on the focused screen reacts to these.
Singleton {
  signal toggleRequested()
  signal showRequested()
  signal hideRequested()
}
