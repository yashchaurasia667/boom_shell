pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
  id: root

  readonly property bool wifiEnabled: Networking.wifiEnabled
  readonly property bool wifiHardwareEnabled: Networking.wifiHardwareEnabled

  // first wifi-capable device, if any — most laptops only have one
  readonly property WifiDevice wifiDevice: {
    for (const d of Networking.devices.values) {
      if (d.type === DeviceType.Wifi) return d
    }
    return null
  }

  readonly property bool connected: wifiDevice?.connected ?? false
  readonly property ObjectModel networks: wifiDevice?.networks ?? null
  readonly property int networkCount: networks?.count ?? 0

  // the network currently marked connected, or null
  readonly property Network connectedNetwork: {
    if (!networks) return null
    for (const n of networks.values) {
      if (n.connected) return n
    }
    return null
  }

  readonly property bool scanning: wifiDevice?.scannerEnabled ?? false

  function setWifiEnabled(enabled: bool): void {
    Networking.wifiEnabled = enabled
  }

  function toggleWifi(): void {
    setWifiEnabled(!Networking.wifiEnabled)
  }

  function startScan(): void {
    if (wifiDevice) wifiDevice.scannerEnabled = true
  }

  function stopScan(): void {
    if (wifiDevice) wifiDevice.scannerEnabled = false
  }

  function connectTo(network: Network): void {
    network.connect()
  }

  function connectWithPassword(network: WifiNetwork, password: string): void {
    network.connectWithPsk(password)
  }

  function disconnectFrom(network: Network): void {
    network.disconnect()
  }

  function forget(network: WifiNetwork): void {
    network.forget()
  }

  // auto-start scanning once a wifi device is found, so `networks` populates
  // without every widget needing to remember to call startScan() itself
  onWifiDeviceChanged: {
    if (wifiDevice) wifiDevice.scannerEnabled = true
  }
}
