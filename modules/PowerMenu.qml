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
  property int panelHeight: 150
  property int panelWidth: 580
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
  WlrLayershell.namespace: "power-menu"
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

  // scrim inside the screen frame (same inset as the app launcher) that fades with the panel
  Rectangle {
    anchors {
      fill: parent
      // topMargin: Global.pillHeight
      // leftMargin: Global.border
      // rightMargin: Global.border
      // bottomMargin: Global.border
    }
    radius: Global.borderRadius
    color: Qt.rgba(Theme.m3shadow.r, Theme.m3shadow.g, Theme.m3shadow.b, 0.3)
    opacity: (root.open && root._ready) ? 1 : 0

    Behavior on opacity {
      NumberAnimation { duration: Global.dur.normal; easing.type: Easing.OutCubic }
    }

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
    height: 0
    focus: root.open

    // spring in, smooth (no overshoot) out
    states: State {
      name: "shown"
      when: root.open && root._ready
      PropertyChanges { target: panel; height: root.panelHeight }
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
      spacing: 18

      Repeater {
        model: root.actions

        delegate: CustomButton {
          id: actionButton
          btnFont: Global.iconFont
          cornerRadius: Global.panelRadius
          
          hoverColor: Theme.m3surface_variant
          baseColor: Theme.m3surface_bright

          implicitWidth: 110
          implicitHeight: 110

          onClicked: root.runAction(modelData.cmd)

          ColumnLayout {
            Layout.alignment: Qt.AlignCenter
            // anchors.centerIn: parent
            spacing: 6

            Icon {
              font.pixelSize: 40
              color: actionButton.hovered ? Theme.m3primary : Theme.m3on_surface
              text: modelData.icon // Fixed typo from modeData to modelData
              Layout.alignment: Qt.AlignCenter
            }

            Label {
              text: modelData.label
              color: actionButton.hovered ? Theme.m3primary : Theme.m3on_surface
              font.pixelSize: 16
              Layout.alignment: Qt.AlignCenter
            }
          }
        }
      }
    }
  }
}
