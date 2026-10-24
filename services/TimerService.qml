pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Countdown timer that lives outside the drawer, so it keeps running
// (and can still ring) after the drawer closes / gets destroyed.
Singleton {
  id: root

  // "idle" | "running" | "paused" | "finished"
  property string status: "idle"
  property int durationSeconds: 300          // what the user dialled in
  property real remainingMs: 300000
  property real _endTime: 0                  // wall-clock ms when it hits zero

  readonly property bool isIdle: status === "idle"
  readonly property bool isRunning: status === "running"
  readonly property bool isPaused: status === "paused"
  readonly property bool isFinished: status === "finished"
  readonly property real progress: durationSeconds > 0
    ? Math.max(0, Math.min(1, remainingMs / (durationSeconds * 1000)))
    : 0

  // Alarm sound (freedesktop theme). Change if you prefer another file.
  property string alarmSound: "/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga"
  property string fallbackSound: "/usr/share/sounds/freedesktop/stereo/complete.oga"

  function setDuration(seconds: int): void {
    if (status !== "idle") return
    durationSeconds = Math.max(0, Math.min(99 * 3600 + 59 * 60 + 59, seconds))
    remainingMs = durationSeconds * 1000
  }

  function start(): void {
    if (durationSeconds <= 0) return
    remainingMs = durationSeconds * 1000
    _endTime = Date.now() + remainingMs
    status = "running"
  }

  function pause(): void {
    if (status !== "running") return
    remainingMs = Math.max(0, _endTime - Date.now())
    status = "paused"
  }

  function resume(): void {
    if (status !== "paused") return
    _endTime = Date.now() + remainingMs
    status = "running"
  }

  // Cancel / dismiss: stops the alarm and returns to the picker
  function reset(): void {
    alarmProc.running = false
    status = "idle"
    remainingMs = durationSeconds * 1000
  }

  function formatSeconds(total: int): string {
    const h = Math.floor(total / 3600)
    const m = Math.floor((total % 3600) / 60)
    const s = total % 60
    const pad = (n) => (n < 10 ? "0" : "") + n
    return h > 0 ? (h + ":" + pad(m) + ":" + pad(s)) : (pad(m) + ":" + pad(s))
  }

  function _finish(): void {
    remainingMs = 0
    status = "finished"

    Quickshell.execDetached([
      "notify-send", "-a", "Timer", "-u", "critical", "-i", "alarm-symbolic",
      "Timer finished",
      formatSeconds(durationSeconds) + " timer is done"
    ])

    alarmProc.running = true
  }

  Timer {
    interval: 100
    repeat: true
    running: root.status === "running"
    onTriggered: {
      root.remainingMs = Math.max(0, root._endTime - Date.now())
      if (root.remainingMs <= 0) root._finish()
    }
  }

  // Rings ~8 times then stops by itself; reset()/dismiss stops it immediately
  Process {
    id: alarmProc
    command: [
      "sh", "-c",
      "f='" + root.alarmSound + "'; [ -f \"$f\" ] || f='" + root.fallbackSound + "'; "
      + "for i in 1 2 3 4 5 6 7 8; do "
      + "paplay \"$f\" 2>/dev/null || pw-play \"$f\" 2>/dev/null || canberra-gtk-play -i alarm-clock-elapsed 2>/dev/null; "
      + "sleep 0.6; done"
    ]
  }
}
