import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Networking
import Quickshell.Bluetooth
import Quickshell.Services.UPower

import qs.common
import qs.components
import qs.services

PanelWindow {
  id: drawer

  // Overall geometry matched to the reference layout (+ NotchShape side ears)
  property int contentWidth: Global.topDrawerWidth
  property int contentHeight: Global.topDrawerHeight
  property int drawerWidth: contentWidth + 2 * (Global.pad + Global.panelRadius)
  property int tabBarHeight: 50
  property int drawerHeight: contentHeight + Global.pad + Global.notchRadius + 10 + tabBarHeight
  property int gridGap: Global.topDrawerGridGap
  property int cardRadius: Global.topDrawerCardRadius

  property bool drawerHovered: false
  property bool _ready: false
  property bool caffeineActive: false

  // Active drawer view: "main" | "wifi" | "bluetooth"
  property string activeView: "main"

  // Active top-level tab: 0 = Dashboard, 1 = Calendar & Timer
  property int currentTab: 0

  signal dismissed()

  // Theme-adaptive palette
  readonly property color cardColor: Theme.m3surface_container_highest
  readonly property color mediaCardColor: Theme.m3surface_bright
  readonly property color activeColor: Theme.m3primary
  readonly property color activeContentColor: Theme.m3on_primary
  readonly property color trackColor: Theme.m3outline_variant
  readonly property color textPrimary: Theme.m3on_surface
  readonly property color textSecondary: Theme.m3on_surface_variant

  // Grant Wayland keyboard focus & hold drawer open while a password/PIN prompt is active
  readonly property bool needsKeyboard: (activeView === "wifi" && wifiPanel.promptOpen)
    || (activeView === "bluetooth" && bluetoothPanel.promptOpen)

  Component.onCompleted: {
    SystemStatsService.pollRam = true
    Qt.callLater(() => { drawer._ready = true })
  }

  Component.onDestruction: {
    SystemStatsService.pollRam = false
    NetworkService.stopScan()
    if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.discovering) {
      Bluetooth.defaultAdapter.discovering = false
    }
  }

  // ── Navigation & Helpers ──

  function openWifiView(): void {
    bluetoothPanel.closePrompt()
    activeView = "wifi"
    if (NetworkService.wifiEnabled) {
      NetworkService.startScan()
    }
  }

  function openBluetoothView(): void {
    wifiPanel.closePrompt()
    activeView = "bluetooth"
    if (Bluetooth.defaultAdapter && Bluetooth.defaultAdapter.enabled) {
      Bluetooth.defaultAdapter.discovering = true
    }
  }

  function switchTab(index: int): void {
    if (index === currentTab) return
    // leaving the dashboard: close any Wi-Fi / Bluetooth sub-view first
    if (activeView !== "main") backToMain()
    currentTab = index
  }

  function backToMain(): void {
    wifiPanel.closePrompt()
    bluetoothPanel.closePrompt()
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

  function runIpcAndClose(target: string): void {
    Quickshell.execDetached(["qs", "ipc", "call", target, "toggle"])
    drawer.drawerHovered = false
    hideTimer.stop()
    drawer.dismissed()
  }

  function openControlCenterAndClose(): void {
    ControlCenterState.showRequested()
    drawer.drawerHovered = false
    hideTimer.stop()
    drawer.dismissed()
  }

  function openSettingsAndClose(): void {
    Global.showSettings()
    drawer.drawerHovered = false
    hideTimer.stop()
    drawer.dismissed()
  }

  function cyclePowerProfile(): void {
    const cur = PowerProfiles.profile
    if (cur === PowerProfile.PowerSaver) {
      PowerProfiles.profile = PowerProfile.Balanced
    } else if (cur === PowerProfile.Balanced) {
      PowerProfiles.profile = PowerProfile.Performance
    } else {
      PowerProfiles.profile = PowerProfile.PowerSaver
    }
  }

  // ── Normalized Models for ConnectionListPanel ──

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
      const openSec = drawer.isWifiOpenSecurity(n)
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
        icon: drawer.wifiSignalIcon(n.signalStrength),
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
        parts.push(Math.round(d.battery * 100) + "% battery")
      }
      return {
        key: d.address,
        title: d.name || d.deviceName || d.address,
        subtitle: parts.join(" • "),
        icon: drawer.btDeviceIcon(d),
        connected: d.connected,
        known: d.paired || d.bonded,
        locked: false,
        rawItem: d
      }
    })
  }

  // Fallback nmcli process for Wi-Fi password connection
  Process {
    id: nmcliConnectProc
    property string ssid: ""
    property string password: ""
    command: ["nmcli", "device", "wifi", "connect", ssid, "password", password]
    onRunningChanged: {
      if (!running) {
        wifiPanel.connecting = false
        wifiPanel.closePrompt()
      }
    }
  }

  // Helper process for Bluetooth PIN pairing when user enters a PIN/passkey
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
        bluetoothPanel.connecting = false
        bluetoothPanel.closePrompt()
      }
    }
  }

  Timer {
    id: wifiConnectTimer
    interval: 2500
    onTriggered: {
      wifiPanel.connecting = false
      if (NetworkService.connectedNetwork && NetworkService.connectedNetwork.name === wifiPanel.selectedKey) {
        wifiPanel.closePrompt()
      } else if (wifiPanel.promptOpen) {
        wifiPanel.statusMessage = "Check password or try again"
      }
    }
  }

  Timer {
    id: btConnectTimer
    interval: 2500
    onTriggered: {
      bluetoothPanel.connecting = false
      if (bluetoothPanel.selectedItem?.rawItem?.connected) {
        bluetoothPanel.closePrompt()
      }
    }
  }

  // ── Window & LayerShell Setup ──

  anchors {
    top: true
    left: true
    right: true
  }

  margins.top: Global.pillHeight

  exclusionMode: ExclusionMode.Ignore
  aboveWindows: false
  color: "transparent"
  implicitHeight: drawerHeight + 100

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "media-drawer"
  WlrLayershell.keyboardFocus: (drawer.open && drawer.needsKeyboard)
    ? WlrKeyboardFocus.Exclusive
    : WlrKeyboardFocus.OnDemand

  readonly property bool anyHovered: drawerHovered || panelHoverHandler.hovered || needsKeyboard

  onAnyHoveredChanged: {
    if (anyHovered) {
      hideTimer.stop()
      closeDelay.stop()
    } else {
      hideTimer.restart()
    }
  }

  onOpenChanged: {
    if (!open) { backToMain(); currentTab = 0 }
  }

  Timer {
    id: hideTimer
    interval: Global.topDrawerHideDelay
    onTriggered: closeDelay.restart()
  }

  Timer {
    id: closeDelay
    interval: Global.dur.normal
    onTriggered: {
      if (!drawer.open) drawer.dismissed()
    }
  }

  readonly property bool open: anyHovered || hideTimer.running

  mask: Region {
    x: panel.x
    y: 0
    width: panel.width
    height: Math.max(0, panel.height)
  }

  component StatProgressBar: Rectangle {
    id: statBar
    property real ratio: 0
    Layout.fillWidth: true
    implicitHeight: 5
    radius: 2.5
    color: drawer.trackColor

    Rectangle {
      anchors.left: parent.left
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      width: Math.max(parent.height, parent.width * Math.max(0, Math.min(1, statBar.ratio)))
      visible: statBar.ratio > 0.005
      radius: parent.radius
      color: drawer.activeColor

      Behavior on width {
        Anim {}
      }
    }
  }

  // ── Main Animated Drawer Container ──

  Item {
    id: panel
    clip: true
    width: drawer.drawerWidth
    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    height: 0

    // spring in, smooth (no overshoot) out
    states: State {
      name: "shown"
      when: drawer.open && drawer._ready
      PropertyChanges { target: panel; height: drawer.drawerHeight }
    }
    transitions: [
      Transition {
        to: "shown"
        Anim { target: panel; property: "height"; curve: Global.spring }
      },
      Transition {
        from: "shown"
        Anim { target: panel; property: "height"; curve: Global.smooth }
      }
    ]

    HoverHandler {
      id: panelHoverHandler
    }

    NotchShape {
      anchors.fill: parent
      edge: "top"
    }

    // ── Tab switcher (top of drawer) ──
    Rectangle {
      id: tabBar
      anchors.top: parent.top
      anchors.topMargin: 8
      anchors.horizontalCenter: parent.horizontalCenter
      height: drawer.tabBarHeight - 10
      width: drawer.contentWidth
      readonly property real tabWidth: (width - 8) / 2
      radius: height / 2
      color: drawer.cardColor

      // sliding highlight
      Rectangle {
        y: 4
        height: parent.height - 8
        width: tabBar.tabWidth
        radius: height / 2
        color: drawer.activeColor
        x: 4 + drawer.currentTab * tabBar.tabWidth
        Behavior on x { Anim {} }
      }

      Row {
        id: tabRow
        anchors.centerIn: parent

        Repeater {
          model: [
            { icon: "dashboard",      label: "Dashboard" },
            { icon: "calendar_month", label: "Calendar & Timer" }
          ]

          delegate: Item {
            required property int index
            required property var modelData
            readonly property bool selected: drawer.currentTab === index
            width: tabBar.tabWidth
            height: tabBar.height

            Row {
              anchors.centerIn: parent
              spacing: 6
              Icon {
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.icon
                font.pixelSize: 18
                color: selected ? drawer.activeContentColor : drawer.textSecondary
              }
              Label {
                anchors.verticalCenter: parent.verticalCenter
                text: modelData.label
                font.pixelSize: 13
                font.bold: selected
                color: selected ? drawer.activeContentColor : drawer.textSecondary
              }
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: drawer.switchTab(index)
            }
          }
        }
      }
    }

    Item {
      id: viewport
      width: drawer.contentWidth
      height: drawer.contentHeight
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Global.pad + Global.notchRadius
      clip: true

      // ════════════════════════════════════════════════════════════════
      // 1. MAIN DASHBOARD VIEW
      // ════════════════════════════════════════════════════════════════
      RowLayout {
        id: mainRow
        anchors.fill: parent
        spacing: drawer.gridGap
        visible: opacity > 0.01
        opacity: (drawer.currentTab === 0 && drawer.activeView === "main") ? 1 : 0
        scale: (drawer.currentTab === 0 && drawer.activeView === "main") ? 1.0 : 0.96

        Behavior on opacity {
          NumberAnimation { duration: Global.dur.fast }
        }
        Behavior on scale {
          Anim {}
        }

        // ── LEFT COLUMN: Quick Toggles + Sliders, MediaPanel, Action Bar ──
        ColumnLayout {
          Layout.fillWidth: true
          Layout.fillHeight: true
          spacing: drawer.gridGap

          // Top Row: 2x2 QuickToggleTile Grid + 2 Vertical Sliders
          RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 186
            spacing: drawer.gridGap

            GridLayout {
              Layout.fillWidth: true
              Layout.fillHeight: true
              columns: 2
              rowSpacing: drawer.gridGap
              columnSpacing: drawer.gridGap

              // Wi-Fi Tile
              QuickToggleTile {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: drawer.cardRadius
                icon: NetworkService.wifiEnabled ? "wifi" : "wifi_off"
                title: "Wi-Fi"
                subtitle: NetworkService.wifiEnabled
                  ? (NetworkService.connectedNetwork?.name || "On")
                  : "Off"
                active: NetworkService.wifiEnabled
                showChevron: true
                onClicked: drawer.openWifiView()
                onIconToggled: NetworkService.toggleWifi()
              }

              // Bluetooth Tile
              QuickToggleTile {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: drawer.cardRadius
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
                onClicked: drawer.openBluetoothView()
                onIconToggled: {
                  if (Bluetooth.defaultAdapter) {
                    Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
                  }
                }
              }

              // Focus (DND) Tile
              QuickToggleTile {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: drawer.cardRadius
                icon: NotificationService.doNotDisturb ? "notifications_off" : "notifications"
                title: "Focus"
                subtitle: NotificationService.doNotDisturb ? "On" : "Off"
                active: NotificationService.doNotDisturb
                onClicked: NotificationService.doNotDisturb = !NotificationService.doNotDisturb
                onIconToggled: NotificationService.doNotDisturb = !NotificationService.doNotDisturb
              }

              // Inbox Tile
              QuickToggleTile {
                Layout.fillWidth: true
                Layout.fillHeight: true
                radius: drawer.cardRadius
                readonly property int notifCount: NotificationService.historyCount
                icon: "forum"
                title: "Inbox"
                subtitle: notifCount + " new"
                active: notifCount > 0
                onClicked: drawer.openControlCenterAndClose()
                onIconToggled: drawer.openControlCenterAndClose()
              }
            }

            // Reusable Vertical Volume Slider
            Slider {
              orientation: Slider.Vertical
              Layout.preferredWidth: 58
              Layout.fillHeight: true
              from: 0; to: 1
              value: AudioService.muted ? 0 : AudioService.volume
              icon: AudioService.muted ? "volume_off" : (AudioService.volume < 0.5 ? "volume_down" : "volume_up")
              iconSize: 28
              onMoved: (v) => AudioService.setVolume(v)
              onIconClicked: AudioService.toggleMute()
            }

            // Reusable Vertical Brightness Slider
            Slider {
              orientation: Slider.Vertical
              Layout.preferredWidth: 58
              Layout.fillHeight: true
              from: 0; to: 1
              value: BrightnessService.brightness
              icon: "brightness_5"
              iconSize: 26
              onMoved: (v) => BrightnessService.setBrightness(v)
            }
          }

          // Middle Row: Reusable MediaPanel
          MediaPanel {
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: 198
            radius: drawer.cardRadius + 2
            active: drawer.open && drawer.currentTab === 0 && drawer.activeView === "main"
          }

          // Bottom Row: Pill Quick-Action Dock
          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 54
            radius: 27
            color: drawer.cardColor

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 14
              anchors.rightMargin: 14
              spacing: 0

              Repeater {
                model: [
                  { id: "launcher",   icon: "grid_view",          highlight: false },
                  { id: "clipboard",  icon: "content_paste",      highlight: false },
                  { id: "wallpaper",  icon: "image",              highlight: false },
                  { id: "screenshot", icon: "photo_camera",       highlight: false },
                  { id: "powermenu",  icon: "power_settings_new", highlight: false },
                  { id: "caffeine",   icon: "coffee",             highlight: drawer.caffeineActive },
                  { id: "profile",    icon: "speed",              highlight: PowerProfiles.profile === PowerProfile.Performance },
                  { id: "settings",   icon: "settings",           highlight: true }
                ]

                delegate: Item {
                  required property var modelData
                  Layout.fillWidth: true
                  Layout.fillHeight: true

                  Rectangle {
                    width: 38
                    height: 38
                    radius: 19
                    anchors.centerIn: parent
                    color: actionMouse.containsMouse ? drawer.mediaCardColor : "transparent"

                    Icon {
                      anchors.centerIn: parent
                      text: modelData.icon
                      font.pixelSize: 21
                      color: modelData.highlight ? drawer.activeColor : drawer.textSecondary
                    }
                  }

                  MouseArea {
                    id: actionMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: {
                      switch (modelData.id) {
                        case "launcher":
                        case "clipboard":
                        case "wallpaper":
                        case "powermenu":
                          drawer.runIpcAndClose(modelData.id)
                          break
                        case "screenshot":
                          Quickshell.execDetached(["sh", "-c", Global.screenshotCmd])
                          drawer.drawerHovered = false
                          drawer.dismissed()
                          break
                        case "caffeine":
                          drawer.caffeineActive = !drawer.caffeineActive
                          break
                        case "profile":
                          drawer.cyclePowerProfile()
                          break
                        case "settings":
                          drawer.openSettingsAndClose()
                          break
                      }
                    }
                  }
                }
              }
            }
          }
        }

        // ── RIGHT COLUMN: System Stats Card (CPU, Memory, Temperature) ──
        Rectangle {
          Layout.preferredWidth: 146
          Layout.fillHeight: true
          radius: drawer.cardRadius + 2
          color: drawer.cardColor

          ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 14

            ColumnLayout {
              Layout.fillWidth: true
              Layout.fillHeight: true
              spacing: 2

              Label {
                text: "CPU"
                font.pixelSize: 13
                color: drawer.textSecondary
              }

              Label {
                text: Math.round(SystemStatsService.cpuUsage) + "%"
                font.pixelSize: 28
                font.bold: true
                color: drawer.textPrimary
              }

              StatProgressBar {
                Layout.topMargin: 12
                ratio: SystemStatsService.cpuUsage / 100
              }

              Item { Layout.fillHeight: true }
            }

            ColumnLayout {
              Layout.fillWidth: true
              Layout.fillHeight: true
              spacing: 2

              Label {
                text: "Memory"
                font.pixelSize: 13
                color: drawer.textSecondary
              }

              Label {
                text: SystemStatsService.ramUsedGb.toFixed(1) + " GB"
                font.pixelSize: 26
                font.bold: true
                color: drawer.textPrimary
              }

              Label {
                text: "of " + Math.max(1, Math.round(SystemStatsService.ramTotalGb)) + " GB"
                font.pixelSize: 12
                color: drawer.textSecondary
              }

              StatProgressBar {
                Layout.topMargin: 12
                ratio: SystemStatsService.ramUsage / 100
              }
              Item { Layout.fillHeight: true }
            }

            ColumnLayout {
              Layout.fillWidth: true
              Layout.fillHeight: true
              spacing: 2

              Label {
                text: "Temperature"
                font.pixelSize: 13
                color: drawer.textSecondary
              }

              Label {
                text: Math.round(SystemStatsService.cpuTemp) + "°C"
                font.pixelSize: 28
                font.bold: true
                color: SystemStatsService.cpuTemp > Global.tempWarnThreshold ? Theme.m3error : drawer.textPrimary
              }

              StatProgressBar {
                Layout.topMargin: 12
                ratio: Math.min(1, SystemStatsService.cpuTemp / 100)
              }

              Item { Layout.fillHeight: true }
            }
          }
        }
      }

      // ════════════════════════════════════════════════════════════════
      // 4. CALENDAR & TIMER TAB (left: calendar, right: timer — equal halves)
      // ════════════════════════════════════════════════════════════════
      RowLayout {
        id: toolsRow
        anchors.fill: parent
        spacing: drawer.gridGap
        visible: opacity > 0.01
        opacity: drawer.currentTab === 1 ? 1 : 0
        scale: drawer.currentTab === 1 ? 1.0 : 0.96

        Behavior on opacity {
          NumberAnimation { duration: Global.dur.fast }
        }
        Behavior on scale {
          Anim {}
        }

        CalendarCard {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.preferredWidth: 1
          radius: drawer.cardRadius + 2
        }

        TimerCard {
          Layout.fillWidth: true
          Layout.fillHeight: true
          Layout.preferredWidth: 1
          radius: drawer.cardRadius + 2
        }
      }

      // ════════════════════════════════════════════════════════════════
      // 2. REUSABLE WI-FI CONNECTION LIST PANEL
      // ════════════════════════════════════════════════════════════════
      ConnectionListPanel {
        id: wifiPanel
        anchors.fill: parent
        visible: opacity > 0.01
        opacity: drawer.activeView === "wifi" ? 1 : 0
        scale: drawer.activeView === "wifi" ? 1.0 : 0.96

        Behavior on opacity {
          NumberAnimation { duration: Global.dur.fast }
        }
        Behavior on scale {
          Anim {}
        }

        title: "Wi-Fi Networks"
        headerIcon: "wifi"
        disabledIcon: "wifi_off"
        emptyIcon: "wifi_find"
        scanIcon: "refresh"
        enabledState: NetworkService.wifiEnabled
        scanning: NetworkService.scanning
        subtitle: {
          if (!NetworkService.wifiEnabled) return "Wi-Fi is turned off"
          if (NetworkService.scanning) return "Scanning for nearby networks..."
          if (NetworkService.connectedNetwork) return "Connected to " + NetworkService.connectedNetwork.name
          return drawer.wifiItemsModel.length + " available networks"
        }
        emptyText: NetworkService.scanning ? "Searching for networks..." : "No Wi-Fi networks found"
        disabledText: "Turn on Wi-Fi to view available networks"

        items: drawer.wifiItemsModel
        promptIcon: "key"
        maskInput: true
        showVisibilityToggle: true
        promptPlaceholder: (selectedItem?.known ?? false)
          ? "Saved network (leave blank or enter new password)..."
          : "Enter Wi-Fi password..."
        connectButtonText: "Connect"

        onBackClicked: drawer.backToMain()

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
            wifiPanel.connecting = true
            NetworkService.connectTo(net)
            wifiConnectTimer.restart()
            return
          }
          NetworkService.stopScan()
          wifiPanel.openPromptFor(item)
        }

        onConnectSubmitted: (item, secret) => {
          if (!item) return
          const net = item.rawItem
          const pwd = (secret || "").trim()
          wifiPanel.connecting = true
          wifiPanel.statusMessage = "Connecting..."

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
      // 3. REUSABLE BLUETOOTH CONNECTION LIST PANEL
      // ════════════════════════════════════════════════════════════════
      ConnectionListPanel {
        id: bluetoothPanel
        anchors.fill: parent
        visible: opacity > 0.01
        opacity: drawer.activeView === "bluetooth" ? 1 : 0
        scale: drawer.activeView === "bluetooth" ? 1.0 : 0.96

        readonly property bool btEnabled: Bluetooth.defaultAdapter?.enabled ?? false
        readonly property bool btScanning: Bluetooth.defaultAdapter?.discovering ?? false

        Behavior on opacity {
          NumberAnimation { duration: Global.dur.fast }
        }
        Behavior on scale {
          Anim {}
        }

        title: "Bluetooth Devices"
        headerIcon: "bluetooth"
        disabledIcon: "bluetooth_disabled"
        emptyIcon: "bluetooth_searching"
        scanIcon: "radar"
        enabledState: btEnabled
        scanning: btScanning
        subtitle: {
          if (!btEnabled) return "Bluetooth is turned off"
          if (btScanning) return "Scanning for nearby devices..."
          return drawer.bluetoothItemsModel.length + " devices"
        }
        emptyText: btScanning ? "Scanning for nearby devices..." : "No Bluetooth devices found"
        disabledText: "Turn on Bluetooth to view available devices"

        items: drawer.bluetoothItemsModel
        promptIcon: "pin"
        maskInput: false
        showVisibilityToggle: false
        promptPlaceholder: "PIN / Passkey (leave blank if none required)..."
        connectButtonText: (selectedItem?.known ?? false) ? "Connect" : "Pair & Connect"

        onBackClicked: drawer.backToMain()

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
          bluetoothPanel.openPromptFor(item)
        }

        onConnectSubmitted: (item, secret) => {
          const dev = item?.rawItem
          if (!dev) return
          bluetoothPanel.connecting = true
          bluetoothPanel.statusMessage = item.known ? "Connecting..." : "Pairing & connecting..."

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
  }
}
