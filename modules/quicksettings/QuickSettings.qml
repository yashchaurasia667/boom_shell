import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower

import qs.common
import qs.components
import qs.services

Item {
  id: root

  // Active sub-view: "main" | "wifi" | "bluetooth"
  property string activeView: "main"

  // Theme-adaptive palette consistent with TopDrawer and reusable components
  property color cardColor: Theme.m3surface_container_highest
  property color elevatedColor: Theme.m3surface_bright
  property color hoverColor: Theme.m3surface_variant

  property color accentColor: Theme.m3primary
  property color onAccentColor: Theme.m3on_primary

  property color activeTileColor: Theme.m3primary
  property color onActiveTileColor: Theme.m3surface
  property color textPrimary: Theme.m3on_surface
  property color textSecondary: Theme.m3on_surface_variant

  implicitWidth: 368
  implicitHeight: activeView === "main" ? mainLayout.implicitHeight : 360

  Behavior on implicitHeight {
    Anim {}
  }

  Component.onDestruction: {
    NetworkService.stopScan()
    if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering) {
      Bluetooth.defaultAdapter.discovering = false
    }
  }

  // ── Helper Functions ──

  function openWifi(): void {
    btListPanel.closePrompt()
    activeView = "wifi"
    if (NetworkService.wifiEnabled) {
      NetworkService.startScan()
    }
  }

  function openBluetooth(): void {
    wifiListPanel.closePrompt()
    activeView = "bluetooth"
    if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) {
      Bluetooth.defaultAdapter.discovering = true
    }
  }

  function backToMain(): void {
    wifiListPanel.closePrompt()
    btListPanel.closePrompt()
    NetworkService.stopScan()
    if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering) {
      Bluetooth.defaultAdapter.discovering = false
    }
    activeView = "main"
  }

  function isWifiOpenSecurity(net): bool {
    return net && net.security !== undefined && net.security === WifiSecurityType.Open
  }

  function wifiSignalIcon(strength: real): string {
    const s = strength ?? 0
    if (s >= 0.75) return "wifi"
    if (s >= 0.50) return "network_wifi_3_bar"
    if (s >= 0.25) return "network_wifi_2_bar"
    return "network_wifi_1_bar"
  }

  function btDeviceIcon(dev): string {
    if (!dev) return "bluetooth"
    const raw = ((dev.icon || "") + " " + (dev.name || "") + " " + (dev.deviceName || "")).toLowerCase()
    if (raw.includes("headphone") || raw.includes("earbud") || raw.includes("airpod") || raw.includes("buds")) return "headphones"
    if (raw.includes("headset") || raw.includes("handsfree")) return "headset_mic"
    if (raw.includes("speaker") || raw.includes("audio") || raw.includes("sound")) return "speaker"
    if (raw.includes("mouse")) return "mouse"
    if (raw.includes("keyboard")) return "keyboard"
    if (raw.includes("phone") || raw.includes("android") || raw.includes("iphone")) return "smartphone"
    if (raw.includes("watch")) return "watch"
    if (raw.includes("gamepad") || raw.includes("controller") || raw.includes("joystick")) return "sports_esports"
    return "bluetooth"
  }

  // ── Normalized Models for Expandable Wi-Fi & Bluetooth Panels ──

  readonly property var wifiItemsModel: {
    const raw = NetworkService.networks?.values ?? []
    const byName = {}
    for (const n of raw) {
      const ssid = (n.name || "").trim()
      if (!ssid) continue
      const existing = byName[ssid]
      if (!existing
          || (n.connected && !existing.connected)
          || (n.known && !existing.known && !existing.connected)
          || ((n.signalStrength ?? 0) > (existing.signalStrength ?? 0) && !existing.connected)) {
        byName[ssid] = n
      }
    }
    const list = Object.values(byName)
    list.sort((a, b) => {
      if (a.connected !== b.connected) return a.connected ? -1 : 1
      if (a.known !== b.known) return a.known ? -1 : 1
      return (b.signalStrength ?? 0) - (a.signalStrength ?? 0)
    })

    return list.map(n => {
      const openSec = root.isWifiOpenSecurity(n)
      const parts = []
      if (n.connected) parts.push("Connected")
      else if (n.stateChanging) parts.push("Connecting...")
      else if (n.known) parts.push("Saved")
      else if (openSec) parts.push("Open")
      else parts.push("Secured")

      if (n.signalStrength !== undefined && n.signalStrength > 0) {
        parts.push(Math.round(n.signalStrength * 100) + "%")
      }
      return {
        key: n.name,
        title: n.name,
        subtitle: parts.join(" • "),
        icon: root.wifiSignalIcon(n.signalStrength),
        connected: n.connected,
        known: n.known,
        locked: !openSec,
        rawItem: n
      }
    })
  }

  readonly property var bluetoothItemsModel: {
    const raw = Bluetooth.devices?.values ?? (Bluetooth.defaultAdapter?.devices?.values ?? [])
    const filtered = []
    for (const d of raw) {
      if (!d) continue
      const hasName = (d.name && d.name.trim() !== "") || (d.deviceName && d.deviceName.trim() !== "")
      if (d.connected || d.paired || d.bonded || hasName) {
        filtered.push(d)
      }
    }
    filtered.sort((a, b) => {
      if (a.connected !== b.connected) return a.connected ? -1 : 1
      if (a.paired !== b.paired) return a.paired ? -1 : 1
      const nameA = (a.name || a.deviceName || a.address || "").toLowerCase()
      const nameB = (b.name || b.deviceName || b.address || "").toLowerCase()
      return nameA.localeCompare(nameB)
    })

    return filtered.map(d => {
      const parts = []
      if (d.connected) parts.push("Connected")
      else if (d.pairing) parts.push("Pairing...")
      else if (d.paired || d.bonded) parts.push("Paired")
      else parts.push("Available")

      if (d.batteryAvailable && d.battery >= 0) {
        parts.push(Math.round(d.battery * 100) + "%")
      }
      return {
        key: d.address,
        title: d.name || d.deviceName || d.address,
        subtitle: parts.join(" • "),
        icon: root.btDeviceIcon(d),
        connected: d.connected,
        known: d.paired || d.bonded,
        locked: false,
        rawItem: d
      }
    })
  }

  Process {
    id: nmcliConnectProc
    property string ssid: ""
    property string password: ""
    command: ["nmcli", "device", "wifi", "connect", ssid, "password", password]
    onRunningChanged: {
      if (!running) {
        wifiListPanel.connecting = false
        wifiListPanel.closePrompt()
      }
    }
  }

  Process {
    id: btPinConnectProc
    property string mac: ""
    property string pin: ""
    command: [
      "sh", "-c",
      `(printf "agent on\ndefault-agent\ntrust ${mac}\npair ${mac}\n${pin}\nyes\nconnect ${mac}\nquit\n"; sleep 3) | bluetoothctl`
    ]
    onRunningChanged: {
      if (!running) {
        btListPanel.connecting = false
        btListPanel.closePrompt()
      }
    }
  }

  Timer {
    id: wifiConnectTimer
    interval: 2500
    onTriggered: {
      wifiListPanel.connecting = false
      if (NetworkService.connectedNetwork && NetworkService.connectedNetwork.name === wifiListPanel.selectedKey) {
        wifiListPanel.closePrompt()
      } else if (wifiListPanel.promptOpen) {
        wifiListPanel.statusMessage = "Check password or try again"
      }
    }
  }

  Timer {
    id: btConnectTimer
    interval: 2500
    onTriggered: {
      btListPanel.connecting = false
      if (btListPanel.selectedItem?.rawItem?.connected) {
        btListPanel.closePrompt()
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // 1. MAIN QUICK SETTINGS VIEW
  // ════════════════════════════════════════════════════════════════
  ColumnLayout {
    id: mainLayout
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    spacing: 10
    visible: opacity > 0.01
    opacity: root.activeView === "main" ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: Global.dur.fast }
    }

    // ── 2x2 Grid of Quick Toggle Cards ──
    GridLayout {
      Layout.fillWidth: true
      columns: 2
      rowSpacing: 8
      columnSpacing: 8

      // Wi-Fi Tile
      QuickToggleTile {
        Layout.fillWidth: true
        implicitHeight: 68
        radius: 18
        icon: NetworkService.wifiEnabled ? "wifi" : "wifi_off"
        title: "Wi-Fi"
        subtitle: NetworkService.wifiEnabled
          ? (NetworkService.connectedNetwork?.name || "On")
          : "Off"
        active: NetworkService.wifiEnabled
        showChevron: true
        onClicked: root.openWifi()
        onIconToggled: NetworkService.toggleWifi()
      }

      // Bluetooth Tile
      QuickToggleTile {
        Layout.fillWidth: true
        implicitHeight: 68
        radius: 18
        readonly property bool btEnabled: Bluetooth.defaultAdapter?.enabled ?? false
        icon: btEnabled ? "bluetooth" : "bluetooth_disabled"
        title: "Bluetooth"
        subtitle: {
          if (!btEnabled) return "Off"
          const devices = Bluetooth.devices?.values ?? []
          for (const d of devices) {
            if (d.connected) return d.name || d.deviceName
          }
          return "On"
        }
        active: btEnabled
        showChevron: true
        onClicked: root.openBluetooth()
        onIconToggled: {
          if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
          }
        }
      }

      // Focus / Do Not Disturb Tile
      QuickToggleTile {
        Layout.fillWidth: true
        implicitHeight: 68
        radius: 18
        icon: NotificationService.doNotDisturb ? "notifications_off" : "notifications"
        title: "Focus"
        subtitle: NotificationService.doNotDisturb ? "Do Not Disturb" : "Off"
        active: NotificationService.doNotDisturb
        onClicked: NotificationService.doNotDisturb = !NotificationService.doNotDisturb
        onIconToggled: NotificationService.doNotDisturb = !NotificationService.doNotDisturb
      }

      // Microphone Mute Tile
      QuickToggleTile {
        Layout.fillWidth: true
        implicitHeight: 68
        radius: 18
        icon: AudioService.sourceMuted ? "mic_off" : "mic"
        title: "Microphone"
        subtitle: AudioService.sourceMuted ? "Muted" : "Active"
        active: !AudioService.sourceMuted
        onClicked: AudioService.toggleSourceMute()
        onIconToggled: AudioService.toggleSourceMute()
      }
    }

    // ── Segmented Power Profile Selector ──
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: 44
      radius: 16
      color: root.cardColor

      RowLayout {
        anchors.fill: parent
        anchors.margins: 4
        spacing: 4

        Repeater {
          model: [
            { key: PowerProfile.PowerSaver,  label: "Saver",       icon: "battery_saver" },
            { key: PowerProfile.Balanced,    label: "Balanced",    icon: "balance" },
            { key: PowerProfile.Performance, label: "Performance", icon: "speed" }
          ]

          delegate: Rectangle {
            id: profileSegment
            required property var modelData
            readonly property bool isCurrent: PowerProfiles.profile === modelData.key

            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: isCurrent
              ? root.activeTileColor
              : (segMouse.containsMouse ? root.elevatedColor : "transparent")

            Behavior on color {
              ColorAnimation { duration: Global.dur.fast }
            }

            RowLayout {
              anchors.centerIn: parent
              spacing: 6

              Icon {
                text: profileSegment.modelData.icon
                font.pixelSize: 17
                color: profileSegment.isCurrent ? root.onActiveTileColor : root.textSecondary
              }

              Label {
                text: profileSegment.modelData.label
                font.pixelSize: 12
                font.bold: profileSegment.isCurrent
                color: profileSegment.isCurrent ? root.onActiveTileColor : root.textPrimary
              }
            }

            MouseArea {
              id: segMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: PowerProfiles.profile = profileSegment.modelData.key
            }
          }
        }
      }
    }

    // ── Volume & Brightness Sliders Card ──
    Rectangle {
      Layout.fillWidth: true
      implicitHeight: slidersCol.implicitHeight + 20
      radius: 18
      color: root.cardColor

      ColumnLayout {
        id: slidersCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 10
        spacing: 8

        // Volume Slider
        Slider {
          Layout.fillWidth: true
          implicitHeight: 36
          from: 0; to: 1
          icon: AudioService.muted
            ? "volume_off"
            : (AudioService.volume < 0.5 ? "volume_down" : "volume_up")
          iconSize: 18
          iconMargin: 12
          trackColor: root.elevatedColor
          fillColor: root.activeTileColor
          activeIconColor: root.onActiveTileColor
          inactiveIconColor: root.textPrimary
          value: AudioService.muted ? 0 : AudioService.volume
          onMoved: (val) => AudioService.setVolume(val)
          onIconClicked: AudioService.toggleMute()
        }

        // Brightness Slider
        Slider {
          Layout.fillWidth: true
          implicitHeight: 36
          from: 0; to: 1
          icon: "brightness_5"
          iconSize: 18
          iconMargin: 12
          trackColor: root.elevatedColor
          fillColor: root.activeTileColor
          activeIconColor: root.onActiveTileColor
          inactiveIconColor: root.textPrimary
          value: BrightnessService.brightness
          onMoved: (val) => BrightnessService.setBrightness(val)
        }
      }
    }
  }

  // ════════════════════════════════════════════════════════════════
  // 2. INLINE EXPANDED WI-FI PANEL
  // ════════════════════════════════════════════════════════════════
  ConnectionListPanel {
    id: wifiListPanel
    anchors.fill: parent
    visible: opacity > 0.01
    opacity: root.activeView === "wifi" ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: Global.dur.fast }
    }

    title: "Wi-Fi"
    headerIcon: "wifi"
    disabledIcon: "wifi_off"
    emptyIcon: "wifi_find"
    scanIcon: "refresh"
    enabledState: NetworkService.wifiEnabled
    scanning: NetworkService.scanning
    subtitle: {
      if (!NetworkService.wifiEnabled) return "Off"
      if (NetworkService.scanning) return "Scanning..."
      if (NetworkService.connectedNetwork) return NetworkService.connectedNetwork.name
      return root.wifiItemsModel.length + " available"
    }
    emptyText: NetworkService.scanning ? "Searching for networks..." : "No networks found"
    disabledText: "Turn on Wi-Fi to view networks"

    items: root.wifiItemsModel
    promptIcon: "key"
    maskInput: true
    showVisibilityToggle: true
    promptPlaceholder: "Password..."
    connectButtonText: "Connect"

    onBackClicked: root.backToMain()

    onPowerToggled: {
      NetworkService.toggleWifi()
      if (!NetworkService.wifiEnabled) {
        Qt.callLater(() => NetworkService.startScan())
      }
    }

    onScanToggled: {
      if (NetworkService.scanning) NetworkService.stopScan()
      else NetworkService.startScan()
    }

    onItemClicked: (item) => {
      const net = item.rawItem
      if (!net) return
      if (!item.locked && !item.known && !item.connected) {
        wifiListPanel.connecting = true
        NetworkService.connectTo(net)
        wifiConnectTimer.restart()
        return
      }
      NetworkService.stopScan()
      wifiListPanel.openPromptFor(item)
    }

    onConnectSubmitted: (item, secret) => {
      if (!item) return
      const net = item.rawItem
      const pwd = (secret || "").trim()
      wifiListPanel.connecting = true
      wifiListPanel.statusMessage = "Connecting..."

      if (net && pwd.length > 0) {
        NetworkService.connectWithPassword(net, pwd)
      } else if (net && (item.known || !item.locked)) {
        NetworkService.connectTo(net)
      } else if (pwd.length > 0) {
        nmcliConnectProc.ssid = item.key
        nmcliConnectProc.password = pwd
        nmcliConnectProc.running = true
      }
      wifiConnectTimer.restart()
    }

    onDisconnectRequested: (item) => {
      if (item?.rawItem) NetworkService.disconnectFrom(item.rawItem)
    }

    onForgetRequested: (item) => {
      if (item?.rawItem) NetworkService.forget(item.rawItem)
    }
  }

  // ════════════════════════════════════════════════════════════════
  // 3. INLINE EXPANDED BLUETOOTH PANEL
  // ════════════════════════════════════════════════════════════════
  ConnectionListPanel {
    id: btListPanel
    anchors.fill: parent
    visible: opacity > 0.01
    opacity: root.activeView === "bluetooth" ? 1 : 0

    readonly property bool btEnabled: Bluetooth.defaultAdapter?.enabled ?? false
    readonly property bool btScanning: Bluetooth.defaultAdapter?.discovering ?? false

    Behavior on opacity {
      NumberAnimation { duration: Global.dur.fast }
    }

    title: "Bluetooth"
    headerIcon: "bluetooth"
    disabledIcon: "bluetooth_disabled"
    emptyIcon: "bluetooth_searching"
    scanIcon: "radar"
    enabledState: btEnabled
    scanning: btScanning
    subtitle: {
      if (!btEnabled) return "Off"
      if (btScanning) return "Scanning..."
      return root.bluetoothItemsModel.length + " devices"
    }
    emptyText: btScanning ? "Scanning for devices..." : "No devices found"
    disabledText: "Turn on Bluetooth to view devices"

    items: root.bluetoothItemsModel
    promptIcon: "pin"
    maskInput: false
    showVisibilityToggle: false
    promptPlaceholder: "PIN / Passkey (optional)..."
    connectButtonText: (selectedItem?.known ?? false) ? "Connect" : "Pair"

    onBackClicked: root.backToMain()

    onPowerToggled: {
      if (Bluetooth.defaultAdapter) {
        const nextState = !Bluetooth.defaultAdapter.enabled
        Bluetooth.defaultAdapter.enabled = nextState
        if (nextState) {
          Qt.callLater(() => { Bluetooth.defaultAdapter.discovering = true })
        }
      }
    }

    onScanToggled: {
      if (Bluetooth.defaultAdapter) {
        Bluetooth.defaultAdapter.discovering = !Bluetooth.defaultAdapter.discovering
      }
    }

    onItemClicked: (item) => {
      if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering) {
        Bluetooth.defaultAdapter.discovering = false
      }
      btListPanel.openPromptFor(item)
    }

    onConnectSubmitted: (item, secret) => {
      const dev = item?.rawItem
      if (!dev) return
      btListPanel.connecting = true
      btListPanel.statusMessage = item.known ? "Connecting..." : "Pairing..."

      const trimmedPin = (secret || "").trim()
      if (trimmedPin.length > 0) {
        btPinConnectProc.mac = dev.address
        btPinConnectProc.pin = trimmedPin
        btPinConnectProc.running = true
      } else {
        dev.trusted = true
        if (!dev.paired) dev.pair()
        dev.connect()
      }
      btConnectTimer.restart()
    }

    onDisconnectRequested: (item) => {
      if (item?.rawItem) item.rawItem.disconnect()
    }

    onForgetRequested: (item) => {
      if (item?.rawItem) item.rawItem.forget()
    }
  }
}
