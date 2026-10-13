import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import qs.common
import qs.components
import qs.services

PanelWindow {
  id: clipboard

  property bool open: false
  property int panelWidth: 650
  property int panelHeight: 450
  property int maxResults: 500

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
    if (open) {
      searchInput.forceActiveFocus()
      ClipboardService.refresh()
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

  IpcHandler {
    target: "clipboard"
    function toggle(): void { clipboard.toggle() }
    function show(): void { clipboard.show() }
    function hide(): void { clipboard.hide() }
  }

  // click-outside-to-close backdrop
  Rectangle {
    anchors {
      fill: parent
      // topMargin: Global.pillHeight
      // leftMargin: Global.border
      // rightMargin: Global.border
      // bottomMargin: Global.border
    }

    color: "transparent"
    // color: Qt.rgba(Theme.m3shadow.r, Theme.m3shadow.g, Theme.m3shadow.b, 0.3)
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
    height: open ? clipboard.panelHeight : 0

    // radius: Global.panelRadius
    color: "transparent"

    y: Global.pillHeight
    Behavior on height {
      NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    Shape {
      anchors.centerIn: parent
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

        PathLine { x: Global.panelRadius; y: Global.notchRadius }
        PathArc {
          x: Global.panelRadius + Global.notchRadius; y: 0
          radiusX: Global.notchRadius; radiusY: Global.notchRadius
          // direction: PathArc.Counterclockwise
        }

        PathLine { x: panelWidth - Global.panelRadius - Global.notchRadius; y: 0 }

        PathArc {
          x: panelWidth - Global.panelRadius; y: Global.notchRadius
          radiusX: Global.notchRadius; radiusY: Global.notchRadius
        }
        PathLine { x: panelWidth - Global.panelRadius; y: panelHeight - Global.panelRadius }

        PathArc {
          x: panelWidth; y: panelHeight
          radiusX: Global.panelRadius; radiusY: Global.panelRadius
          direction: PathArc.Counterclockwise
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
          text: "content_paste"
          font.pixelSize: 24
          color: Theme.m3on_surface
        }

        TextInput {
          id: searchInput
          Layout.fillWidth: true
          font.pixelSize: 18
          color: Theme.m3on_surface
          clip: true

          onTextChanged: ClipboardService.filterText = text

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
        model: ScriptModel {
          id: filteredEntries
          values: {
            const q = searchInput.text.trim().toLowerCase()
            const all = ClipboardService.entries
            const matches = q === "" ? all : all.filter(e => e.preview.toLowerCase().includes(q))
            return matches.slice(0, clipboard.maxResults)
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
              color: index === listView.currentIndex ? Theme.m3surface : Theme.m3on_surface
              font.pixelSize: 18
              font.weight: 450
              elide: Text.ElideRight
              wrapMode: resultRow.modelData.isImage ? Text.NoWrap : Text.NoWrap
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
