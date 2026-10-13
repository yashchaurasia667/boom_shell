import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes

import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import qs.common
import qs.components

PanelWindow {
  id: wallpaper

  property bool open: false
  property int panelWidth: 1290
  property int panelHeight: 650
  property string wallpaperDir: Quickshell.env("HOME") + "/Pictures/wall"
  property var wallpapers: []
  property bool applying: false

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
    onTriggered: wallpaper.closed()
  }

  onOpenChanged: {
    if (open) {
      refresh()
    } else {
      hideDelay.restart()
    }
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "wallpaper-switcher"
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  function show(): void {
    open = true
  }

  function hide(): void {
    open = false
    wallpaper.wallpapers = []
  }

  function toggle(): void {
    if (open) hide()
    else show()
  }

  function refresh(): void {
    listProc.running = true
  }

  function apply(path: string): void {
    if (wallpaper.applying) return
    wallpaper.applying = true

    swwwProc.path = path
    swwwProc.running = true
  }

  // IpcHandler {
  //   target: "wallpaper"
  //   function toggle(): void { wallpaper.toggle() }
  //   function show(): void { wallpaper.show() }
  //   function hide(): void { wallpaper.hide() }
  // }

  // list wallpaper files in the directory
  Process {
    id: listProc
    command: ["bash", "-c", `find "${wallpaper.wallpaperDir}" -type f \\( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.webp" \\) | sort`]
    stdout: StdioCollector {
      onStreamFinished: {
        wallpaper.wallpapers = text.split("\n").filter(l => l.length > 0)
      }
    }
  }

  // commands run sequentially: swww -> cp -> matugen
  Process {
    id: swwwProc
    property string path: ""
    command: ["awww", "img", path, "--transition-type=random"]
    onRunningChanged: if (!running) cpProc.running = true
  }

  Process {
    id: cpProc
    command: ["cp", swwwProc.path, "/opt/wal.png"]
    onRunningChanged: if (!running) matugenProc.running = true
  }

  Process {
    id: matugenProc
    command: ["matugen", "image", swwwProc.path, "-m", "dark", "--source-color-index", "0"]
    onRunningChanged: if (!running) {
      wallpaper.applying = false
      wallpaper.hide()
    }
  }

  // click-outside-to-close backdrop
  Rectangle {
    anchors.fill: parent
    color: "transparent"
    radius: Global.borderRadius

    MouseArea {
      anchors.fill: parent
      onClicked: wallpaper.hide()
    }
  }

  Rectangle {
    id: panel
    clip: true
    anchors {
      bottom: parent.bottom
      horizontalCenter: parent.horizontalCenter
    }
    width: wallpaper.panelWidth
    height: open ? wallpaper.panelHeight : 0

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
          text: "wallpaper"
          font.pixelSize: 24
          color: Theme.m3on_surface
        }

        Label {
          Layout.fillWidth: true
          text: wallpaper.applying ? "Applying..." : "Choose a wallpaper"
          font.pixelSize: 18
          font.weight: 450
          color: Theme.m3on_surface
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: Global.panelRadius
        Layout.rightMargin: Global.panelRadius
        height: 1
        color: Theme.m3surface_variant
      }

      GridView {
        id: grid
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: Global.panelRadius
        Layout.rightMargin: Global.panelRadius

        clip: true
        cellWidth: 300
        cellHeight: 193
        model: wallpaper.wallpapers

        delegate: Rectangle {
          id: cell
          required property string modelData
          required property int index

          width: grid.cellWidth - 8
          height: grid.cellHeight - 8
          radius: 8
          color: "transparent"
          border.color: hoverArea.containsMouse ? Theme.m3primary : "transparent"
          border.width: 2
          opacity: wallpaper.applying ? 0.5 : 1.0

          Image {
            anchors.fill: parent
            anchors.margins: 2
            source: "file://" + cell.modelData
            fillMode: Image.PreserveAspectCrop
            asynchronous: true
            cache: false

            Rectangle {
              anchors.fill: parent
              visible: parent.status !== Image.Ready
              color: Theme.m3surface_variant
              radius: 6
            }
          }

          MouseArea {
            id: hoverArea
            anchors.fill: parent
            hoverEnabled: true
            enabled: !wallpaper.applying
            onClicked: wallpaper.apply(cell.modelData)
          }
        }

        Label {
          anchors.centerIn: parent
          visible: grid.count === 0
          text: "No wallpapers found"
          color: Theme.m3on_surface
          opacity: 0.5
        }
      }
    }
  }
}
