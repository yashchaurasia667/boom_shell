import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import qs.components
import qs.common

PanelWindow {
  id: root

  property bool open: false
  property int panelHeight: 160
  property int panelWidth: 660
  property string pendingCmd: ""

  readonly property var actions: [
    { id: "lock",     icon: "lock",               label: "Lock",     cmd: "hyprlock" },
    { id: "logout",   icon: "logout",             label: "Logout",   cmd: "hyprctl dispatch exit" },
    { id: "reboot",   icon: "autorenew",          label: "Reboot",   cmd: "reboot" },
    { id: "shutdown", icon: "power_settings_new", label: "Shutdown", cmd: "shutdown now" }
  ]

  Process {
    id: proc
    function execute(cmd) {
      command = ["sh", "-c", cmd]
      running = true
    }
  }

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
    interval: 150
    onTriggered: {
      if (root.pendingCmd) {
        proc.execute(root.pendingCmd)
        root.pendingCmd = ""
      }
    }
  }

  onOpenChanged: {
    if (!open) hideDelay.restart()
  }

  // IPC stuff
  IpcHandler {
    target: "powermenu"
    function toggle() { root.toggle() }
    function show() { root.show() }
    function hide() { root.hide() }
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

  // DISABLE WHEN DONE MAKING COMPONENT
  // pass through clicks
  // mask: Region {
  //   item: root
  // }

  Rectangle {
    anchors.fill: parent
    color: Qt.rgba(Theme.m3shadow.r, Theme.m3shadow.g, Theme.m3shadow.b, 0.3)
    MouseArea {
      anchors.fill: parent
      onClicked: root.hide()
    }
  }

  Item {
    id: slideContent
    width: parent.width
    height: parent.height
    focus: root.open

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

    y: root.open ? 0 : root.panelHeight
    Behavior on y {
      NumberAnimation {
        duration: 150
        easing.type: Easing.OutCubic
      }
    }

    Shape {
      anchors.bottom: parent.bottom
      anchors.horizontalCenter: parent.horizontalCenter

      Layout.fillWidth: true
      Layout.fillHeight: true
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        startX: 0; startY: panelHeight
        fillRule: ShapePath.OddEvenFill
        fillColor: Theme.m3surface
        strokeColor: "transparent"

        PathArc {
          x: Global.panelRadius; y: panelHeight - Global.panelRadius
          radiusX: Global.panelRadius; radiusY: Global.panelRadius
          direction: PathArc.Counterclockwise
        }

        PathLine { x: Global.panelRadius; y: Global.panelRadius }
        PathArc {
          x: 2 * Global.panelRadius; y: 0
          radiusX: Global.panelRadius; radiusY: Global.panelRadius
          // direction: PathArc.Counterclockwise
        }

        PathLine { x: panelWidth - 2 * Global.panelRadius; y: 0 }

        PathArc {
          x: panelWidth - Global.panelRadius; y: Global.panelRadius
          radiusX: Global.panelRadius; radiusY: Global.panelRadius
        }
        PathLine { x: panelWidth - Global.panelRadius; y: panelHeight - Global.panelRadius }

        PathArc {
          x: panelWidth; y: panelHeight
          radiusX: Global.panelRadius; radiusY: Global.panelRadius
          direction: PathArc.Counterclockwise
        }
      }
    }

    RowLayout {
      id: buttons
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Global.pad
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
