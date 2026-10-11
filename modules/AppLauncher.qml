import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import qs.common
import qs.components

PanelWindow {
  id: launcher

  property bool open: false
  property int launcherWidth: 800
  property int launcherHeight: 400
  property int maxResults: 10

  anchors {
    top: true
    bottom: true
    left: true
    right: true
  }

  exclusionMode: ExclusionMode.Ignore
  aboveWindows: true
  color: "transparent"
  visible: open || hideDelay.running

  Timer {
    id: hideDelay
    interval: 150
    onTriggered: {}
  }

  onOpenChanged: {
    if (open) searchInput.forceActiveFocus()
    else hideDelay.restart()
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "app-launcher"
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  function show(): void {
    searchInput.text = ""
    listView.currentIndex = 0
    open = true
  }

  function hide(): void {
    open = false
  }

  function toggle(): void {
    if (open) hide()
    else show()
  }

  function launch(entry): void {
    if (!entry) return

    if (entry.runInTerminal) {
      const terminal = Quickshell.env("TERMINAL") ?? "alacritty"
      Quickshell.execDetached([terminal, "-e", ...entry.command])
    } else {
      Quickshell.execDetached(entry.command)
    }

    hide()
  }

  IpcHandler {
    target: "launcher"
    function toggle(): void { launcher.toggle() }
    function show(): void { launcher.show() }
    function hide(): void { launcher.hide() }
  }

  // click-outside-to-close backdrop
  Rectangle {
    anchors {
      fill: parent
      topMargin: Global.pillHeight
      leftMargin: Global.border
      rightMargin: Global.border
      bottomMargin: Global.border
    }

    color: Qt.rgba(Theme.m3shadow.r, Theme.m3shadow.g, Theme.m3shadow.b, 0.3)
    radius: Global.borderRadius

    MouseArea {
      anchors.fill: parent
      onClicked: launcher.hide()
    }
  }

  Rectangle {
    id: panel
    clip: true
    anchors {
      // top: parent.top
      // topMargin: Global.pillHeight
      horizontalCenter: parent.horizontalCenter
    }
    width: launcher.launcherWidth
    height: open ? launcher.launcherHeight : 0

    radius: Global.panelRadius
    color: "transparent"
    // color: Theme.m3surface

    y: Global.pillHeight
    Behavior on height {
      NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    // swallow clicks so they don't fall through to the backdrop
    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    Shape {
      // anchors.fill: parent
      anchors.centerIn: parent
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        startX: 0; startY: 0
        fillRule: ShapePath.OddEvenFill
        fillColor: Theme.m3surface
        strokeColor: "transparent"
        // strokeWidth: 2

        PathArc {
          x: Global.panelRadius; y: Global.panelRadius
          radiusX: Global.panelRadius; radiusY: Global.panelRadius
        }

        PathLine { x: Global.panelRadius; y: launcherHeight - Global.notchRadius }
        PathArc {
          x: Global.panelRadius + Global.notchRadius; y: launcherHeight
          radiusX: Global.notchRadius; radiusY: Global.notchRadius
          direction: PathArc.Counterclockwise
        }

        PathLine { x: launcherWidth - Global.panelRadius - Global.notchRadius; y: launcherHeight }

        PathArc {
          x: launcherWidth - Global.panelRadius; y: launcherHeight - Global.notchRadius
          radiusX: Global.notchRadius; radiusY: Global.notchRadius
          direction: PathArc.Counterclockwise
        }
        PathLine { x: launcherWidth - Global.panelRadius; y: Global.panelRadius }

        PathArc {
          x: launcherWidth; y: 0
          radiusX: Global.panelRadius; radiusY: Global.panelRadius
        }
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: Global.pad
      spacing: Global.pad

      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Global.panelRadius
        Layout.rightMargin: Global.panelRadius
        spacing: 20

        Icon {
          text: "search"
          font.pixelSize: 24
          color: Theme.m3on_surface
        }

        TextInput {
          id: searchInput
          Layout.fillWidth: true
          font.pixelSize: 16
          color: Theme.m3on_surface
          clip: true

          Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
              launcher.hide()
              event.accepted = true
            } else if (event.key === Qt.Key_Down) {
              listView.currentIndex = Math.min(listView.count - 1, listView.currentIndex + 1)
              event.accepted = true
            } else if (event.key === Qt.Key_Up) {
              listView.currentIndex = Math.max(0, listView.currentIndex - 1)
              event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              launcher.launch(filteredApps.values[listView.currentIndex])
              event.accepted = true
            }
          }

          Label {
            visible: searchInput.text === ""
            text: "Search..."
            color: Theme.m3on_surface
            opacity: 0.5
            font.pixelSize: 16
          }
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: Global.panelRadius
        Layout.rightMargin: Global.panelRadius
        height: 1
        color: Theme.m3surface_variant
      }

      ListView {
        id: listView
        Layout.fillWidth: true
        Layout.fillHeight: true

        Layout.leftMargin: Global.panelRadius
        Layout.rightMargin: Global.panelRadius

        clip: true
        model: ScriptModel {
          id: filteredApps
          values: {
            const all = [...DesktopEntries.applications.values]
            const q = searchInput.text.trim().toLowerCase()

            const matches = q === "" ? all : all.filter(entry => {
              if (entry.name.toLowerCase().includes(q)) return true
              if (entry.genericName.toLowerCase().includes(q)) return true
              return entry.keywords.some(k => k.toLowerCase().includes(q))
            })

            return matches.slice(0, launcher.maxResults)
          }
        }

        delegate: Rectangle {
          id: resultRow
          required property var modelData
          required property int index

          width: ListView.view.width
          height: 48 + Global.pad
          radius: 8
          color: index === listView.currentIndex ? Theme.m3primary : "transparent"

          RowLayout {
            anchors.fill: parent
            anchors.margins: 8
            anchors.topMargin: Global.pad
            anchors.bottomMargin: Global.pad
            spacing: 20

            Image {
              Layout.preferredWidth: 40
              Layout.preferredHeight: 40
              source: Quickshell.iconPath(resultRow.modelData.icon, "application-x-executable")
              fillMode: Image.PreserveAspectFit
              asynchronous: true
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 0

              Label {
                Layout.fillWidth: true
                text: resultRow.modelData.name
                color: index === listView.currentIndex ? Theme.m3surface : Theme.m3primary
                font.weight: 600
                font.pixelSize: 16
                elide: Text.ElideRight
              }

              Label {
                Layout.fillWidth: true
                visible: resultRow.modelData.genericName !== " "
                text: resultRow.modelData.genericName
                font.pixelSize: 12
                color: index === listView.currentIndex ? Theme.m3surface : Theme.m3on_surface
                opacity: 0.6
                elide: Text.ElideRight
              }
            }
          }

          MouseArea {
            anchors.fill: parent
            onClicked: launcher.launch(resultRow.modelData)
            onEntered: listView.currentIndex = resultRow.index
            hoverEnabled: true
          }
        }

        Label {
          anchors.centerIn: parent
          visible: listView.count === 0
          text: "No results"
          color: Theme.m3on_surface
          opacity: 0.5
        }
      }
    }
  }
}
