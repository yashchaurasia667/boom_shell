import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland

import qs.components
import qs.common

PanelWindow {
  id: root

  property bool open: false
  property bool _ready: false
  property int panelHeight: 160
  property int panelWidth: 660
  property string pendingCmd: ""
  signal dismissed()

  Component.onCompleted: Qt.callLater(() => { root._ready = true })

  readonly property var actions: [
    { id: "lock",     icon: "lock",               label: "Lock",     cmd: "hyprlock" },
    { id: "logout",   icon: "logout",             label: "Logout",   cmd: "hyprctl dispatch exit" },
    { id: "reboot",   icon: "autorenew",          label: "Reboot",   cmd: "reboot" },
    { id: "shutdown", icon: "power_settings_new", label: "Shutdown", cmd: "shutdown now" }
  ]

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  aboveWindows: true
  color: "transparent"
  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  visible: open || hideDelay.running
  Timer {
    id: hideDelay
    interval: Global.dur.normal
    onTriggered: {
      if (root.pendingCmd) {
        const cmd = root.pendingCmd
        root.pendingCmd = ""
        Quickshell.execDetached(["sh", "-c", cmd])
      }
      if (!root.open) root.dismissed()
    }
  }

  onOpenChanged: {
    if (open) {
      hideDelay.stop()
      Qt.callLater(() => panel.forceActiveFocus())
    } else {
      hideDelay.restart()
    }
  }

  function show(): void {
    open = true
  }

  function hide(): void {
    open = false
  }

  function toggle(): void {
    if (open) hide()
    else show()
  }

  function runAction(cmd: string): void {
    pendingCmd = cmd
    root.hide()
  }

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(Theme.m3shadow.r, Theme.m3shadow.g, Theme.m3shadow.b, 0.3)
    MouseArea {
      anchors.fill: parent
      onClicked: root.hide()
    }
  }

  Item {
    id: panel
    clip: true
    anchors.bottom: parent.bottom
    anchors.horizontalCenter: parent.horizontalCenter
    width: root.panelWidth
    height: (root.open && root._ready) ? root.panelHeight : 0
    focus: root.open

    Behavior on height {
      Anim {}
    }

    Keys.onPressed: (event) => {
      let action = null
      switch (event.key) {
        case Qt.Key_S: action = "shutdown"; break
        case Qt.Key_R: action = "reboot"; break
        case Qt.Key_L: action = "lock"; break
        case Qt.Key_O: action = "logout"; break
        case Qt.Key_Escape: root.hide(); return
        default: return
      }

      const match = root.actions.find(a => a.id === action)
      if (match) {
        root.runAction(match.cmd)
      }
      event.accepted = true
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    NotchShape {
      anchors.fill: parent
      edge: "bottom"
      cornerRadius: Global.panelRadius
    }

    RowLayout {
      id: buttons
      anchors.top: parent.top
      anchors.topMargin: root.panelHeight - 120 - Global.pad
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: 24

      Repeater {
        model: root.actions

        delegate: CustomButton {
          btnFont: Global.iconFont
          cornerRadius: Global.panelRadius
          fontSize: 52

          text: modelData.icon
          implicitWidth: 120
          implicitHeight: 120

          onClicked: root.runAction(modelData.cmd)
        }
      }
    }
  }
}
