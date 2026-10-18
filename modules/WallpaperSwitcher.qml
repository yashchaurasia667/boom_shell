import QtQuick
import QtQuick.Layouts
import QtCore

import Quickshell
import Quickshell.Wayland
import Quickshell.Io

import qs.common
import qs.components

PanelWindow {
  id: wallpaper

  property bool open: false
  property bool _ready: false
  property int panelWidth: Global.wallpaperPanelWidth
  property int panelHeight: Global.wallpaperPanelHeight
  property int thumbWidth: Global.wallpaperThumbWidth
  property int thumbHeight: Global.wallpaperThumbHeight
  property int thumbSpacing: Global.wallpaperThumbSpacing
  property string wallpaperDir: Global.wallpaperDir
  property string currentWallpaperFile: Global.currentWallpaperFile
  property var wallpapers: []
  property bool applying: false
  signal dismissed()

  // matugen "-t" scheme types
  readonly property var schemes: [
    { id: "scheme-tonal-spot",  label: "Tonal Spot" },
    { id: "scheme-vibrant",     label: "Vibrant" },
    { id: "scheme-expressive",  label: "Expressive" },
    { id: "scheme-content",     label: "Content" },
    { id: "scheme-fidelity",    label: "Fidelity" },
    { id: "scheme-neutral",     label: "Neutral" },
    { id: "scheme-monochrome",  label: "Monochrome" },
    { id: "scheme-rainbow",     label: "Rainbow" },
    { id: "scheme-fruit-salad", label: "Fruit Salad" }
  ]

  readonly property int sourceCount: 4

  readonly property string currentName: {
    const p = wallpaper.wallpapers[list.currentIndex]
    return p ? p.split("/").pop() : ""
  }

  Component.onCompleted: Qt.callLater(() => { wallpaper._ready = true })

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
      if (!wallpaper.open) {
        wallpaper.wallpapers = []
        wallpaper.dismissed()
      }
    }
  }

  onOpenChanged: {
    if (open) {
      hideDelay.stop()
      refresh()
      Qt.callLater(() => panel.forceActiveFocus())
    } else {
      hideDelay.restart()
    }
  }

  WlrLayershell.layer: WlrLayer.Overlay
  WlrLayershell.namespace: "wallpaper-switcher"
  WlrLayershell.keyboardFocus: open ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None

  // ── API ──

  function show(): void { open = true }
  function hide(): void { open = false }
  function toggle(): void { if (open) hide(); else show() }

  function refresh(): void {
    listProc.running = true
  }

  function apply(path: string): void {
    if (!path || wallpaper.applying) return
    wallpaper.applying = true
    Global.wallLast = path

    applyProc.path = path
    applyProc.running = true
  }

  function applyCurrent(): void {
    apply(wallpaper.wallpapers[list.currentIndex])
  }

  // ── selection helpers ──

  function setIndex(i: int): void {
    const n = wallpaper.wallpapers.length
    if (n === 0) return
    list.currentIndex = Math.max(0, Math.min(n - 1, i))
  }

  function step(delta: int): void {
    setIndex(list.currentIndex + delta)
  }

  function setScheme(id: string): void {
    Global.wallScheme = id
  }

  function cycleScheme(delta: int): void {
    const n = wallpaper.schemes.length
    let i = wallpaper.schemes.findIndex(s => s.id === Global.wallScheme)
    if (i < 0) i = 0
    setScheme(wallpaper.schemes[(i + delta + n) % n].id)
  }

  function setContrast(v: real): void {
    const clamped = Math.max(-1, Math.min(1, Math.round(v * 20) / 20))
    Global.wallContrast = clamped
  }

  function setSourceIndex(i: int): void {
    Global.wallUseCustom = false
    Global.wallSourceIndex = i
  }

  function cycleSource(delta: int): void {
    const n = wallpaper.sourceCount
    setSourceIndex((Global.wallUseCustom ? 0 : Global.wallSourceIndex + delta + n) % n)
  }

  function setCustomColor(text: string): bool {
    const m = /^#?([0-9a-fA-F]{6})$/.exec(text.trim())
    if (!m) return false
    Global.wallCustomColor = "#" + m[1].toLowerCase()
    Global.wallUseCustom = true
    return true
  }

  function contrastLabel(): string {
    const c = Global.wallContrast
    if (c === 0) return "Standard"
    return (c > 0 ? "+" : "") + c.toFixed(2)
  }

  // ── processes ──

  Process {
    id: listProc
    command: ["sh", "-c", "find \"$1\" -type f \\( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \\) | sort", "sh", wallpaper.wallpaperDir]
    stdout: StdioCollector {
      onStreamFinished: {
        wallpaper.wallpapers = text.split("\n").filter(l => l.length > 0)
        Qt.callLater(() => {
          const i = Math.max(0, wallpaper.wallpapers.indexOf(Global.wallLast))
          list.currentIndex = i
          list.positionViewAtIndex(i, ListView.Center)
        })
      }
    }
  }

  Process {
    id: applyProc
    property string path: ""
    command: [
      "sh", "-c",
      "awww img \"$1\" --transition-type=random; cp \"$1\" \"$4\"; "
      + "case \"$5\" in "
      + "hex:*) matugen color hex \"${5#hex:}\" -m \"$6\" -t \"$2\" --contrast=\"$3\" ;; "
      + "*) matugen image \"$1\" -m \"$6\" -t \"$2\" --contrast=\"$3\" --source-color-index \"${5#idx:}\" ;; "
      + "esac",
      "sh", path, Global.wallScheme, Global.wallContrast.toFixed(2), wallpaper.currentWallpaperFile,
      Global.wallUseCustom ? "hex:" + Global.wallCustomColor : "idx:" + Global.wallSourceIndex,
      Global.matugenMode
    ]
    onExited: {
      wallpaper.applying = false
      wallpaper.hide()
    }
  }

  // ── click-outside-to-close backdrop ──
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
    focus: wallpaper.open
    anchors {
      bottom: parent.bottom
      horizontalCenter: parent.horizontalCenter
    }
    width: wallpaper.panelWidth
    height: 0
    color: "transparent"

    states: State {
      name: "shown"
      when: wallpaper.open && wallpaper._ready
      PropertyChanges { target: panel; height: wallpaper.panelHeight }
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
      const k = event.key
      if (customField.activeFocus) return
      if (k === Qt.Key_Escape) wallpaper.hide()
      else if (k === Qt.Key_Left || k === Qt.Key_H) wallpaper.step(-1)
      else if (k === Qt.Key_Right || k === Qt.Key_L) wallpaper.step(1)
      else if (k === Qt.Key_PageUp) wallpaper.step(-3)
      else if (k === Qt.Key_PageDown) wallpaper.step(3)
      else if (k === Qt.Key_Home) wallpaper.setIndex(0)
      else if (k === Qt.Key_End) wallpaper.setIndex(wallpaper.wallpapers.length - 1)
      else if (k === Qt.Key_Return || k === Qt.Key_Enter) wallpaper.applyCurrent()
      else if (k === Qt.Key_Up) wallpaper.setContrast(Global.wallContrast + 0.1)
      else if (k === Qt.Key_Down) wallpaper.setContrast(Global.wallContrast - 0.1)
      else if (k === Qt.Key_Comma) wallpaper.cycleSource(-1)
      else if (k === Qt.Key_Period) wallpaper.cycleSource(1)
      else if (k === Qt.Key_Tab) wallpaper.cycleScheme(1)
      else if (k === Qt.Key_Backtab) wallpaper.cycleScheme(-1)
      else if (k >= Qt.Key_1 && k <= Qt.Key_9 && (k - Qt.Key_1) < wallpaper.schemes.length)
        wallpaper.setScheme(wallpaper.schemes[k - Qt.Key_1].id)
      else return

      event.accepted = true
    }

    MouseArea {
      anchors.fill: parent
      onClicked: {}
    }

    NotchShape {
      anchors.fill: parent
      edge: "bottom"
    }

    ColumnLayout {
      width: wallpaper.panelWidth - 2 * Global.pad
      height: wallpaper.panelHeight - 2 * Global.pad
      anchors.top: parent.top
      anchors.topMargin: Global.pad
      anchors.horizontalCenter: parent.horizontalCenter
      spacing: Global.pad

      // ── header ──
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

        Label {
          visible: wallpaper.wallpapers.length > 0
          Layout.maximumWidth: 420
          text: wallpaper.currentName + "   " + (list.currentIndex + 1) + " / " + wallpaper.wallpapers.length
          font.pixelSize: 13
          color: Theme.m3on_surface_variant
        }
      }

      Rectangle {
        Layout.fillWidth: true
        Layout.leftMargin: Global.panelRadius
        Layout.rightMargin: Global.panelRadius
        Layout.preferredHeight: 1
        color: Theme.m3surface_variant
      }

      // ── matugen options: scheme type + contrast ──
      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Global.panelRadius
        Layout.rightMargin: Global.panelRadius
        Layout.preferredHeight: 32
        spacing: 20

        Row {
          id: chipRow
          spacing: 6

          Repeater {
            model: wallpaper.schemes

            delegate: Rectangle {
              id: chip
              required property var modelData
              required property int index
              readonly property bool selected: Global.wallScheme === chip.modelData.id

              height: 32
              width: chipLabel.implicitWidth + 24
              radius: height / 2
              color: chip.selected
                ? Theme.m3secondary_container
                : (chipMouse.containsMouse ? Theme.m3surface_container_high : "transparent")
              border.width: chip.selected ? 0 : 1
              border.color: Theme.m3outline_variant

              Behavior on color {
                ColorAnimation { duration: Global.dur.fast }
              }

              Label {
                id: chipLabel
                anchors.centerIn: parent
                text: chip.modelData.label
                font.pixelSize: 12
                font.weight: chip.selected ? 600 : 500
                color: chip.selected ? Theme.m3on_secondary_container : Theme.m3on_surface_variant
              }

              MouseArea {
                id: chipMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: wallpaper.setScheme(chip.modelData.id)
              }
            }
          }
        }

        Item { Layout.fillWidth: true }

        Label {
          text: "Contrast"
          font.pixelSize: 13
          color: Theme.m3on_surface_variant
        }

        Slider {
          id: contrastSlider
          Layout.preferredWidth: 220
          Layout.preferredHeight: 28
          Layout.alignment: Qt.AlignVCenter
          from: -1
          to: 1
          icon: "contrast"
          iconSize: 16
          showPercentage: false
          wheelStep: 0.05
          onMoved: (v) => wallpaper.setContrast(v)

          Binding {
            target: contrastSlider
            property: "value"
            value: Global.wallContrast
          }
        }

        Label {
          Layout.preferredWidth: 64
          horizontalAlignment: Text.AlignRight
          text: wallpaper.contrastLabel()
          font.pixelSize: 13
          font.weight: 500
          color: Theme.m3on_surface
        }
      }

      // ── source color: extracted color index or a custom hex ──
      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Global.panelRadius
        Layout.rightMargin: Global.panelRadius
        Layout.preferredHeight: 32
        spacing: 6

        Label {
          Layout.rightMargin: 14
          text: "Source color"
          font.pixelSize: 13
          color: Theme.m3on_surface_variant
        }

        Repeater {
          model: wallpaper.sourceCount

          delegate: Rectangle {
            id: srcChip
            required property int index
            readonly property bool selected: !Global.wallUseCustom && Global.wallSourceIndex === srcChip.index

            Layout.preferredHeight: 32
            Layout.preferredWidth: srcLabel.implicitWidth + 24
            radius: 16
            color: srcChip.selected ? Theme.m3secondary_container
              : (srcMouse.containsMouse ? Theme.m3surface_container_high : "transparent")
            border.width: srcChip.selected ? 0 : 1
            border.color: Theme.m3outline_variant

            Behavior on color {
              ColorAnimation { duration: Global.dur.fast }
            }

            Label {
              id: srcLabel
              anchors.centerIn: parent
              text: srcChip.index === 0 ? "Auto" : "Color " + (srcChip.index + 1)
              font.pixelSize: 12
              font.weight: srcChip.selected ? 600 : 500
              color: srcChip.selected ? Theme.m3on_secondary_container : Theme.m3on_surface_variant
            }

            MouseArea {
              id: srcMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: { panel.forceActiveFocus(); wallpaper.setSourceIndex(srcChip.index) }
            }
          }
        }

        // custom hex color
        Rectangle {
          Layout.preferredHeight: 32
          Layout.preferredWidth: 130
          radius: 16
          color: Global.wallUseCustom ? Theme.m3secondary_container : "transparent"
          border.width: Global.wallUseCustom ? 0 : 1
          border.color: customField.activeFocus ? Theme.m3primary : Theme.m3outline_variant

          Behavior on color {
            ColorAnimation { duration: Global.dur.fast }
          }

          Rectangle {
            id: swatch
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.verticalCenter: parent.verticalCenter
            width: 16
            height: 16
            radius: 8
            color: Global.wallCustomColor
            border.width: 1
            border.color: Theme.m3outline
          }

          TextInput {
            id: customField
            anchors.left: swatch.right
            anchors.leftMargin: 8
            anchors.right: parent.right
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: Global.wallCustomColor
            maximumLength: 7
            clip: true
            font.family: Global.font
            font.pixelSize: 12
            color: Global.wallUseCustom ? Theme.m3on_secondary_container : Theme.m3on_surface_variant
            selectionColor: Theme.m3primary
            selectedTextColor: Theme.m3on_primary
            selectByMouse: true

            function commit(): void {
              if (!wallpaper.setCustomColor(text)) text = Global.wallCustomColor
              panel.forceActiveFocus()
            }

            onAccepted: commit()
            Keys.onEscapePressed: { text = Global.wallCustomColor; panel.forceActiveFocus() }
            onActiveFocusChanged: if (activeFocus) selectAll()
          }
        }

        Item { Layout.fillWidth: true }
      }

      // ── wallpapers: a single horizontally scrolling row ──
      Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        Layout.leftMargin: Global.panelRadius
        Layout.rightMargin: Global.panelRadius

        ListView {
          id: list
          anchors.fill: parent
          clip: true
          orientation: ListView.Horizontal
          spacing: wallpaper.thumbSpacing
          cacheBuffer: wallpaper.thumbWidth
          model: wallpaper.wallpapers
          boundsBehavior: Flickable.StopAtBounds

          highlightRangeMode: ListView.StrictlyEnforceRange
          preferredHighlightBegin: (width - wallpaper.thumbWidth) / 2
          preferredHighlightEnd: (width + wallpaper.thumbWidth) / 2
          highlightMoveDuration: Global.dur.normal
          highlightMoveVelocity: -1

          delegate: Item {
            id: cell
            required property string modelData
            required property int index
            readonly property bool current: ListView.isCurrentItem

            width: wallpaper.thumbWidth
            height: list.height

            Rectangle {
              id: thumb
              anchors.centerIn: parent
              width: wallpaper.thumbWidth
              height: wallpaper.thumbHeight
              radius: 12
              color: Theme.m3surface_variant
              scale: cell.current ? 1.0 : 0.9
              opacity: wallpaper.applying ? 0.5 : (cell.current || hoverArea.containsMouse ? 1.0 : 0.7)
              border.width: cell.current ? 3 : (hoverArea.containsMouse ? 2 : 0)
              border.color: cell.current ? Theme.m3primary : Theme.m3outline

              Behavior on scale {
                Anim {}
              }
              Behavior on opacity {
                NumberAnimation { duration: Global.dur.fast }
              }

              Image {
                anchors.fill: parent
                anchors.margins: thumb.border.width
                source: "file://" + cell.modelData
                sourceSize: Qt.size(wallpaper.thumbWidth, wallpaper.thumbHeight)
                fillMode: Image.PreserveAspectCrop
                asynchronous: true
                cache: false
                opacity: status === Image.Ready ? 1 : 0

                Behavior on opacity {
                  NumberAnimation { duration: Global.dur.fast }
                }
              }

              MouseArea {
                id: hoverArea
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                enabled: !wallpaper.applying
                onClicked: {
                  panel.forceActiveFocus()
                  list.currentIndex = cell.index
                }
              }
            }
          }
        }

        MouseArea {
          anchors.fill: parent
          acceptedButtons: Qt.NoButton
          onWheel: (event) => {
            const raw = event.angleDelta.y !== 0 ? event.angleDelta.y : event.angleDelta.x
            if (raw !== 0) wallpaper.step(raw > 0 ? -1 : 1)
          }
        }

        Label {
          anchors.centerIn: parent
          visible: wallpaper.wallpapers.length === 0
          text: "No wallpapers found in " + wallpaper.wallpaperDir
          color: Theme.m3on_surface
          opacity: 0.5
        }
      }

      // ── key hints + buttons ──
      RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: Global.panelRadius
        Layout.rightMargin: Global.panelRadius
        Layout.preferredHeight: 34
        spacing: 10

        Label {
          Layout.fillWidth: true
          text: "←/→ browse   Enter apply   Tab/1-9 scheme   ,/. source color   ↑/↓ contrast   Esc close"
          font.pixelSize: 12
          color: Theme.m3on_surface_variant
          opacity: 0.7
        }

        CustomButton {
          text: "Cancel"
          implicitWidth: 90
          implicitHeight: 34
          cornerRadius: 17
          baseColor: Theme.m3surface_container_highest
          hoverColor: Theme.m3surface_bright
          pressColor: Theme.m3surface_variant
          textColor: Theme.m3on_surface
          onClicked: wallpaper.hide()
        }

        CustomButton {
          text: "OK"
          implicitWidth: 90
          implicitHeight: 34
          cornerRadius: 17
          enabled: !wallpaper.applying && wallpaper.wallpapers.length > 0
          opacity: enabled ? 1 : 0.5
          onClicked: wallpaper.applyCurrent()
        }
      }
    }
  }
}
