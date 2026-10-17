pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  // Opt-in flags for unused stats so we don't spawn nvidia-smi or parse /proc/meminfo every 2s at idle
  property bool pollRam: false
  property bool pollGpu: false

  // --- CPU ---
  readonly property real cpuUsage: _cpuUsage    // 0.0–100.0
  readonly property real cpuTemp: _cpuTemp      // °C

  // --- RAM ---
  readonly property real ramUsage: _ramUsage    // 0.0–100.0
  readonly property real ramUsedGb: _ramUsedGb
  readonly property real ramTotalGb: _ramTotalGb

  // --- GPU (NVIDIA) ---
  readonly property real gpuUsage: _gpuUsage    // 0.0–100.0
  readonly property real gpuTemp: _gpuTemp      // °C

  property real _cpuUsage: 0
  property real _cpuTemp: 0
  property real _ramUsage: 0
  property real _ramUsedGb: 0
  property real _ramTotalGb: 0
  property real _gpuUsage: 0
  property real _gpuTemp: 0

  property var _prevIdle: 0
  property var _prevTotal: 0

  Timer {
    interval: 2000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: {
      statFile.reload()
      cpuTempFile.reload()
      if (root.pollRam) meminfoFile.reload()
      if (root.pollGpu) gpuProcess.running = true
    }
  }

  // /proc/stat — CPU usage via delta between polls
  FileView {
    id: statFile
    path: "/proc/stat"
    onLoaded: {
      const line = text().split("\n")[0] // "cpu  user nice system idle iowait irq softirq ..."
      const parts = line.trim().split(/\s+/).slice(1).map(Number)
      const idle = parts[3] + parts[4] // idle + iowait
      const total = parts.reduce((a, b) => a + b, 0)

      const deltaIdle = idle - root._prevIdle
      const deltaTotal = total - root._prevTotal

      if (root._prevTotal > 0 && deltaTotal > 0) {
        const nextUsage = Math.round((1 - deltaIdle / deltaTotal) * 100)
        // Only assign when the integer percentage changes to avoid unnecessary bar repaints
        if (nextUsage !== root._cpuUsage) {
          root._cpuUsage = nextUsage
        }
      }

      root._prevIdle = idle
      root._prevTotal = total
    }
  }

  // /proc/meminfo — RAM usage (polled only when pollRam is true)
  FileView {
    id: meminfoFile
    path: "/proc/meminfo"
    onLoaded: {
      if (!root.pollRam) return
      const lines = text().split("\n")
      const get = (key) => {
        const line = lines.find(l => l.startsWith(key))
        return line ? parseInt(line.match(/\d+/)[0]) : 0 // kB
      }

      const total = get("MemTotal:")
      const available = get("MemAvailable:")
      const used = total - available

      root._ramTotalGb = total / 1024 / 1024
      root._ramUsedGb = used / 1024 / 1024
      root._ramUsage = total > 0 ? (used / total) * 100 : 0
    }
  }

  // nvidia-smi — GPU usage + temp (polled only when pollGpu is true)
  Process {
    id: gpuProcess
    command: ["nvidia-smi", "--query-gpu=utilization.gpu,temperature.gpu", "--format=csv,noheader,nounits"]
    stdout: StdioCollector {
      onStreamFinished: {
        const parts = text.trim().split(",").map(s => parseFloat(s.trim()))
        if (parts.length === 2 && !isNaN(parts[0]) && !isNaN(parts[1])) {
          root._gpuUsage = parts[0]
          root._gpuTemp = parts[1]
        }
      }
    }
  }

  // CPU temp — adjust hwmon path for your sensor
  FileView {
    id: cpuTempFile
    path: "/sys/class/hwmon/hwmon5/temp1_input"
    onLoaded: {
      const milliC = parseInt(text().trim())
      if (!isNaN(milliC)) {
        const nextTemp = Math.round(milliC / 1000)
        if (nextTemp !== root._cpuTemp) {
          root._cpuTemp = nextTemp
        }
      }
    }
  }
}
