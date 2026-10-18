pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.common

Singleton {
  id: root

  property real brightness: 0.5
  property int maxBrightness: 0
  property bool ready: false
  property string _detectedDevice: "intel_backlight"
  readonly property string _device: Global.backlightDevice.trim() !== ""
    ? Global.backlightDevice.trim()
    : root._detectedDevice

  function setBrightness(value: real): void {
    if (!ready) return
    root.brightness = Math.max(0, Math.min(1, value))

    const target = Math.round(root.brightness * root.maxBrightness)
    setProcess.command = ["brightnessctl", "set", target + ""]
    setProcess.running = true
  }

  // Fallback slow poll for drivers that don't emit inotify on sysfs brightness
  Timer {
    interval: Math.max(500, Global.brightnessPollInterval)
    running: root.ready
    repeat: true
    triggeredOnStart: false
    onTriggered: currentFile.reload()
  }

  FileView {
    id: maxFile
    path: "/sys/class/backlight/" + root._device + "/max_brightness"
    onLoaded: {
      root.maxBrightness = parseInt(text().trim())
      root.ready = root.maxBrightness > 0
    }
  }

  FileView {
    id: currentFile
    path: "/sys/class/backlight/" + root._device + "/brightness"
    watchChanges: true
    onFileChanged: reload()
    onLoaded: {
      if (root.maxBrightness > 0) {
        const current = parseInt(text().trim())
        const newBrightness = current / root.maxBrightness
        if (Math.abs(newBrightness - root.brightness) > 0.001) {
          root.brightness = newBrightness
        }
      }
    }
  }

  Process {
    id: setProcess
  }

  Component.onCompleted: {
    deviceListProcess.running = true
  }

  Process {
    id: deviceListProcess
    command: ["ls", "/sys/class/backlight"]
    stdout: StdioCollector {
      onStreamFinished: {
        const devices = text.trim().split("\n").filter(d => d.length > 0)
        if (devices.length > 0) root._detectedDevice = devices[0]
      }
    }
  }
}
