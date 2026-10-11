import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Services.UPower

import qs.common
import qs.components
import qs.services

ColumnLayout {
  id: panel
  spacing: 12
  property int tileWidth: 60
  property int iconSize: 20

  // --- toggle row: wifi / bluetooth / dnd / mic ---
  RowLayout {
    Layout.fillWidth: true
    spacing: 10

    // Wifi
    Rectangle {
      Layout.preferredWidth: tileWidth
      Layout.preferredHeight: tileWidth
      radius: 12
      color: NetworkService.wifiEnabled ? Theme.m3primary : Theme.m3surface_variant

      Icon {
        anchors.centerIn: parent
        color: NetworkService.wifiEnabled ? Theme.m3surface : Theme.m3primary
        text: NetworkService.wifiEnabled ? "wifi" : "wifi_off"
        font.pixelSize: iconSize
      }

      MouseArea {
        anchors.fill: parent
        onClicked: NetworkService.toggleWifi()
      }
    }

    // Bluetooth
    Rectangle {
      Layout.preferredWidth: tileWidth
      Layout.preferredHeight: tileWidth
      radius: 12
      color: Bluetooth.defaultAdapter?.enabled ? Theme.m3primary : Theme.m3surface_variant

      Icon {
        anchors.centerIn: parent
        color: Bluetooth.defaultAdapter?.enabled ? Theme.m3surface : Theme.m3primary
        text: "bluetooth"
        font.pixelSize: iconSize
      }

      MouseArea {
        anchors.fill: parent
        onClicked: {
          if (Bluetooth.defaultAdapter) {
            Bluetooth.defaultAdapter.enabled = !Bluetooth.defaultAdapter.enabled
          }
        }
      }
    }

    // DND
    Rectangle {
      Layout.preferredWidth: tileWidth
      Layout.preferredHeight: tileWidth
      radius: 12
      color: NotificationService.doNotDisturb ? Theme.m3primary : Theme.m3surface_variant

      Icon {
        anchors.centerIn: parent
        color: NotificationService.doNotDisturb ? Theme.m3surface: Theme.m3primary
        text: NotificationService.doNotDisturb ? "notifications_off" : "notifications"
        font.pixelSize: iconSize
      }

      MouseArea {
        anchors.fill: parent
        onClicked: NotificationService.doNotDisturb = !NotificationService.doNotDisturb
      }
    }

    // Mic mute
    Rectangle {
      Layout.preferredWidth: tileWidth
      Layout.preferredHeight: tileWidth
      radius: 12
      color: AudioService.sourceMuted ? Theme.m3primary : Theme.m3surface_variant

      Icon {
        anchors.centerIn: parent
        color: AudioService.sourceMuted ? Theme.m3surface : Theme.m3primary
        text: AudioService.sourceMuted ? "mic_off" : "mic"
        font.pixelSize: iconSize
      }

      MouseArea {
        anchors.fill: parent
        onClicked: AudioService.toggleSourceMute()
      }
    }
  }

  // --- power profile ---
  RowLayout {
    Layout.fillWidth: true
    spacing: 6

    Repeater {
      model: [
        { key: PowerProfile.PowerSaver, label: "Saver", icon: "battery_saver" },
        { key: PowerProfile.Balanced, label: "Balanced", icon: "balance" },
        { key: PowerProfile.Performance, label: "Performance", icon: "speed" }
      ]

      delegate: Rectangle {
        required property var modelData
        Layout.fillWidth: true
        implicitHeight: 40
        radius: 10
        color: PowerProfiles.profile === modelData.key ? Theme.m3primary : Theme.m3surface_variant

        RowLayout {
          anchors.centerIn: parent
          spacing: 4
          Icon { 
            text: modelData.icon
            color: PowerProfiles.profile === modelData.key ? Theme.m3surface : Theme.m3primary
            font.pixelSize: iconSize
          }
          Label { 
            text: modelData.label 
            color: PowerProfiles.profile === modelData.key ? Theme.m3surface : Theme.m3primary
            font.pixelSize: 12 
          }
        }

        MouseArea {
          anchors.fill: parent
          onClicked: PowerProfiles.profile = modelData.key
        }
      }
    }
  }

  // --- volume slider ---
  RowLayout {
    Layout.fillWidth: true
    spacing: 10

    Slider {
      Layout.fillWidth: true
      from: 0; to: 1
      icon: AudioService.muted ? "volume_off" : "volume_up"
      value: AudioService.volume
      onMoved: AudioService.setVolume(value)
      onIconClicked: AudioService.toggleMute()
    }
  }

  // --- brightness slider ---
  RowLayout {
    Layout.fillWidth: true
    spacing: 10

    Slider {
      Layout.fillWidth: true
      from: 0; to: 1
      icon: "brightness_6"
      value: BrightnessService.brightness
      onMoved: BrightnessService.setBrightness(value)
    }
  }
}
