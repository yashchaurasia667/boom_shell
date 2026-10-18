import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland

import qs.common
import qs.components
import qs.services

PanelWindow {
  id: root

  property int hoverZoneWidth: Global.border + Global.quickSlidersTriggerWidth
  property int sliderHeight: Global.quickSlidersHeight
  property int sliderWidth: Global.quickSlidersWidth
  property int panelSpacing: Global.quickSlidersSpacing
  property bool triggerHovered: false
  property bool _ready: false
  signal dismissed()

  Component.onCompleted: Qt.callLater(() => { root._ready = true })

  readonly property int panelHeight: sliderHeight * 2 + panelSpacing + 2 * (Global.pad + Global.panelRadius)
  readonly property int panelWidth: sliderWidth + Global.pad * 2
  readonly property int targetWidth: panelWidth + hoverZoneWidth

  anchors {
    right: true
  }

  exclusionMode: ExclusionMode.Ignore
  aboveWindows: false
  color: "transparent"

  implicitWidth: targetWidth + 60
  implicitHeight: panelHeight

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "quick-sliders-popup"

  readonly property bool hovered: root.triggerHovered || hoverZoneHandler.hovered || panelHoverHandler.hovered
  readonly property bool open: root.hovered || hideTimer.running

  mask: Region {
    x: root.width - root.hoverZoneWidth
    y: 0
    width: root.hoverZoneWidth
    height: root.height

    Region {
      x: panel.x
      y: panel.y
      width: Math.max(0, panel.width)
      height: panel.height
      intersection: Intersection.Combine
    }
  }

  onHoveredChanged: {
    if (hovered) {
      hideTimer.stop()
      closeDelay.stop()
    } else {
      hideTimer.restart()
    }
  }

  Timer {
    id: hideTimer
    interval: 200
    onTriggered: closeDelay.restart()
  }

  Timer {
    id: closeDelay
    interval: Global.dur.normal
    onTriggered: {
      if (!root.open) root.dismissed()
    }
  }

  Item {
    id: hoverZone
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.bottom: parent.bottom
    width: root.hoverZoneWidth

    HoverHandler {
      id: hoverZoneHandler
    }
  }

  Item {
    id: panel
    clip: true
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    height: root.panelHeight
    width: 0

    states: State {
      name: "shown"
      when: root.open && root._ready
      PropertyChanges { target: panel; width: root.targetWidth }
    }
    transitions: [
      Transition {
        to: "shown"
        Anim { target: panel; property: "width"; curve: Global.spring }
      },
      Transition {
        from: "shown"
        Anim { target: panel; property: "width"; curve: Global.smooth }
      }
    ]

    HoverHandler {
      id: panelHoverHandler
    }

    NotchShape {
      anchors.fill: parent
      edge: "right"
    }

    ColumnLayout {
      width: root.panelWidth - Global.pad * 2
      anchors.left: parent.left
      anchors.leftMargin: Global.pad
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.topMargin: Global.pad + Global.panelRadius
      anchors.bottomMargin: Global.pad + Global.panelRadius
      spacing: root.panelSpacing

      Slider {
        orientation: Slider.Vertical
        Layout.preferredHeight: root.sliderHeight
        Layout.preferredWidth: root.sliderWidth
        Layout.alignment: Qt.AlignHCenter
        from: 0; to: 1
        icon: AudioService.muted ? "volume_off" : "volume_up"
        iconSize: 20
        fontSize: 14
        value: AudioService.volume
        onMoved: (value) => AudioService.setVolume(value)
        onIconClicked: AudioService.toggleMute()
      }

      Slider {
        orientation: Slider.Vertical
        Layout.preferredHeight: root.sliderHeight
        Layout.preferredWidth: root.sliderWidth
        Layout.alignment: Qt.AlignHCenter
        from: 0; to: 1
        icon: "brightness_5"
        iconSize: 20
        fontSize: 14
        value: BrightnessService.brightness
        onMoved: (value) => BrightnessService.setBrightness(value)
      }
    }
  }
}
