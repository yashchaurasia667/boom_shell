pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

import qs.common

Singleton {
  id: root
  property bool on: false
  property int temperature: Global.nightLight

  Process {
    id: nightLight
    command: ["gammastep", "-O", root.temperature.toString()]

    onStarted: root.on = true
    onExited: (code, status) => { root.on = false }
  }

  function start(): void {
    if(!nightLight.running) {
      nightLight.running = true
    }
  }

  function stop(): void {
    if(nightLight.running) {
      nightLight.running = false
    }
  }

  function toggle(): void {
    if(nightLight.running) {
      stop()
    } else {
      start()
    }
  }

  onTemperatureChanged: {
    if (nightLight.running) {
      nightLight.running = false
      Qt.callLater(start)
    }
  }
}

