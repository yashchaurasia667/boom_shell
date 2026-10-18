import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import qs.common
import qs.components
import qs.services

PanelWindow {
  id: clipboard

  property bool open: false
  property bool _ready: false
  property int panelWidth: Global.clipboardWidth
  property int panelHeight: Global.clipboardHeight
  property int maxResults: Global.clipboardMaxResults
  signal dismissed()

  Component.onCompleted: Qt.callLater(() => { clipboard._ready = true })

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
      if (!clipboard.open) {
        ClipboardService.clear()
        clipboard.dismissed()
      }
    }
  }

  onOpenChanged: {
    if (open) {
      hideDelay.stop()
      ClipboardService.refresh()
      Qt.callLater(() => searchInput.forceActiveFocus())
    } else {
      hideDelay.restart()
    }
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "clipboard-popup"
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

  function select(entry): void {
    if (!entry) return
    ClipboardService.select(entry.id)
    hide()
  }

  Rectangle {
    anchors.fill: parent
    color: "transparent"
    radius: Global.borderRadius

    MouseArea {
      anchors.fill: parent
      onClicked: clipboard.hide()
    }
  }

  Rectangle {
    id: panel
    clip: true
    anchors {
      bottom: parent.bottom
      horizontalCenter: parent.horizontalCenter
    }
    width: clipboard.panelWidth
    height: 0

    color: "transparent"

    states: State {
      name: "shown"
      when: clipboard.open && clipboard._ready
      PropertyChanges { target: panel; height: clipboard.panelHeight }
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
      edge: "bottom"
    }

    ColumnLayout {
      width: clipboard.panelWidth - 2 * Global.pad
      height: clipboard.panelHeight - 2 * Global.pad
      anchors.top: parent.top
      anchors.topMargin: Global.pad
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Global.pad

      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Global.panelRadius
        Layout.rightMargin: Global.panelRadius
        spacing: 20

        Icon {
          text: "content_paste"
          font.pixelSize: 24
          color: Theme.m3on_surface
        }

        TextInput {
          id: searchInput
          Layout.fillWidth: true
          font.family: Global.font
          font.pixelSize: 18
          color: Theme.m3on_surface
          selectionColor: Theme.m3primary
          selectedTextColor: Theme.m3on_primary
          clip: true

          onTextChanged: listView.currentIndex = 0

          Keys.onPressed: (event) => {
            if (event.key === Qt.Key_Escape) {
              clipboard.hide()
              event.accepted = true
            } else if (event.key === Qt.Key_Down) {
              listView.currentIndex = Math.min(listView.count - 1, listView.currentIndex + 1)
              event.accepted = true
            } else if (event.key === Qt.Key_Up) {
              listView.currentIndex = Math.max(0, listView.currentIndex - 1)
              event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
              clipboard.select(filteredEntries.values[listView.currentIndex])
              event.accepted = true
            } else if (event.key === Qt.Key_Delete && (event.modifiers & Qt.ShiftModifier)) {
              const entry = filteredEntries.values[listView.currentIndex]
              if (entry) ClipboardService.remove(entry.preview)
              event.accepted = true
            }
          }

          Label {
            visible: searchInput.text === ""
            text: "Search clipboard..."
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
          id: filteredEntries
          values: {
            const q = searchInput.text.trim().toLowerCase()
            const all = ClipboardService.entries
            if (q === "") return all.slice(0, clipboard.maxResults)
            const matches = []
            for (let i = 0; i < all.length; i++) {
              if (all[i].preview.toLowerCase().includes(q)) {
                matches.push(all[i])
                if (matches.length >= clipboard.maxResults) break
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
          height: resultRow.modelData.isImage ? 120 : 60
          radius: 8
          color: index === listView.currentIndex ? Theme.m3primary : "transparent"

          Behavior on color {
            ColorAnimation { duration: Global.dur.fast }
          }

          Component.onCompleted: {
            if (resultRow.modelData.isImage)
              ClipboardService.ensureThumbnail(resultRow.modelData.id)
          }

          RowLayout {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 12

            Image {
              visible: resultRow.modelData.isImage
              Layout.preferredWidth: 100
              Layout.preferredHeight: 100
              fillMode: Image.PreserveAspectCrop
              asynchronous: true
              cache: false
              sourceSize: Qt.size(100, 100)
              source: resultRow.modelData.thumbPath ? "file://" + resultRow.modelData.thumbPath : ""

              Rectangle {
                anchors.fill: parent
                visible: parent.status !== Image.Ready
                color: Theme.m3surface_variant
                radius: 4
              }
            }

            Label {
              Layout.fillWidth: true
              verticalAlignment: Text.AlignVCenter
              text: resultRow.modelData.preview
              color: index === listView.currentIndex ? Theme.m3on_primary : Theme.m3on_surface
              font.pixelSize: 18
              font.weight: 450
              elide: Text.ElideRight
              wrapMode: Text.NoWrap
            }
          }

          MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: true
            onEntered: listView.currentIndex = resultRow.index
            onClicked: mouse => {
              if (mouse.button === Qt.RightButton)
                ClipboardService.remove(resultRow.modelData.preview)
              else
                clipboard.select(resultRow.modelData)
            }
          }
        }

        Label {
          anchors.centerIn: parent
          visible: listView.count === 0
          text: "No clipboard history"
          color: Theme.m3on_surface
          opacity: 0.5
        }
      }
    }
  }
}
