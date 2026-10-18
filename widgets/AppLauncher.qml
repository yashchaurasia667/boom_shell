import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import qs.common
import qs.components

PanelWindow {
  id: launcher

  property bool open: false
  property bool _ready: false
  property int launcherWidth: Global.launcherWidth
  property int launcherHeight: Global.launcherHeight
  property int maxResults: Global.launcherMaxResults
  signal dismissed()

  Component.onCompleted: Qt.callLater(() => { launcher._ready = true })

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
    interval: Global.dur.normal
    onTriggered: {
      if (!launcher.open) launcher.dismissed()
    }
  }

  onOpenChanged: {
    if (open) {
      hideDelay.stop()
      Qt.callLater(() => searchInput.forceActiveFocus())
    } else {
      hideDelay.restart()
    }
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
      const terminal = Quickshell.env("TERMINAL") || Global.terminal || "alacritty"
      Quickshell.execDetached([terminal, "-e", ...entry.command])
    } else {
      Quickshell.execDetached(entry.command)
    }

    hide()
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

    opacity: (launcher.open && launcher._ready) ? 1 : 0
    Behavior on opacity {
      NumberAnimation { duration: Global.dur.normal; easing.type: Easing.OutCubic }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: launcher.hide()
    }
  }

  Rectangle {
    id: panel
    clip: true
    anchors {
      top: parent.top
      topMargin: Global.pillHeight
      horizontalCenter: parent.horizontalCenter
    }
    width: launcher.launcherWidth
    height: 0

    color: "transparent"

    states: State {
      name: "shown"
      when: launcher.open && launcher._ready
      PropertyChanges { target: panel; height: launcher.launcherHeight }
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

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    NotchShape {
      anchors.fill: parent
      edge: "top"
    }

    ColumnLayout {
      width: launcher.launcherWidth - 2 * Global.pad
      height: launcher.launcherHeight - 2 * Global.pad
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Global.pad
      anchors.horizontalCenter: parent.horizontalCenter
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
          font.family: Global.font
          font.pixelSize: 16
          color: Theme.m3on_surface
          selectionColor: Theme.m3primary
          selectedTextColor: Theme.m3on_primary
          clip: true

          onTextChanged: listView.currentIndex = 0

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
        cacheBuffer: 0

        onCurrentIndexChanged: positionViewAtIndex(currentIndex, ListView.Contain)

        model: ScriptModel {
          id: filteredApps
          values: {
            if (!launcher.open) return []
            const all = DesktopEntries.applications.values
            const q = searchInput.text.trim().toLowerCase()

            if (q === "") {
              return all.slice(0, launcher.maxResults)
            }

            const matches = []
            for (let i = 0; i < all.length; i++) {
              const entry = all[i]
              if (entry.name.toLowerCase().includes(q) ||
                  entry.genericName.toLowerCase().includes(q) ||
                  entry.keywords.some(k => k.toLowerCase().includes(q))) {
                matches.push(entry)
                if (matches.length >= launcher.maxResults) break
              }
            }

            return matches
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

          Behavior on color {
            ColorAnimation { duration: Global.dur.fast }
          }

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
              sourceSize: Qt.size(40, 40)
              fillMode: Image.PreserveAspectFit
              asynchronous: true
              cache: false
            }

            ColumnLayout {
              Layout.fillWidth: true
              spacing: 0

              Label {
                Layout.fillWidth: true
                text: resultRow.modelData.name
                color: index === listView.currentIndex ? Theme.m3on_primary : Theme.m3primary
                font.weight: 600
                font.pixelSize: 16
                elide: Text.ElideRight
              }

              Label {
                Layout.fillWidth: true
                visible: (resultRow.modelData.genericName ?? "").trim() !== ""
                text: resultRow.modelData.genericName
                font.pixelSize: 12
                color: index === listView.currentIndex ? Theme.m3on_primary : Theme.m3on_surface
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
