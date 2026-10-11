import QtQuick
import QtQuick.Shapes
import QtQuick.Layouts

import Quickshell
import Quickshell.Wayland

import qs.common
import qs.components
import qs.services

PanelWindow {
  id: root 

  property int hoverZoneWidth: Global.border + 4
  property int sliderHeight: 150
  property int sliderWidth: 40
  property int panelSpacing: 12

  readonly property int panelHeight: sliderHeight * 2 + panelSpacing + 2 * (Global.pad + Global.panelRadius)
  readonly property int panelWidth: sliderWidth + Global.pad * 2

  anchors {
    right: true
  }

  exclusionMode: ExclusionMode.Ignore
  aboveWindows: false
  color: "transparent"

  implicitWidth: hoverZoneWidth + panelWidth
  implicitHeight: panelHeight

  WlrLayershell.layer: WlrLayer.Top
  WlrLayershell.namespace: "quick-sliders-popup"

  readonly property bool hovered: hoverZoneHandler.hovered || panelHoverHandler.hovered

  mask: Region {
    x: root.width - root.hoverZoneWidth
    y: 0
    width: root.hoverZoneWidth
    height: root.height

    Region {
      x: panel.x
      y: panel.y
      width: panel.width
      height: panel.height
      intersection: Intersection.Combine
    }
  }

  onHoveredChanged: {
    if (hovered) {
      hideTimer.stop()
    } else {
      hideTimer.restart()
    }
  }

  Timer {
    id: hideTimer
    interval: 200
    onTriggered: {}
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
    width: root.panelWidth
    height: root.panelHeight
    anchors.verticalCenter: parent.verticalCenter

    x: root.hovered || hideTimer.running
      ? root.width - root.hoverZoneWidth - root.panelWidth
      : root.width

    Behavior on x {
      NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
    }

    HoverHandler {
      id: panelHoverHandler
    }

    Shape {
      anchors.fill: parent
      preferredRendererType: Shape.CurveRenderer

      ShapePath {
        startX: root.width; startY: 0
        fillRule: ShapePath.OddEvenFill
        fillColor: Theme.m3surface
        strokeColor: "transparent"

        PathArc {
          x: root.width - Global.panelRadius; y: Global.panelRadius
          radiusX: Global.panelRadius; radiusY: Global.panelRadius
        }
        PathLine {
          x: Global.notchRadius; y: Global.panelRadius
        }
        PathArc {
          x: 0; y: Global.panelRadius + Global.notchRadius
          radiusX: Global.notchRadius; radiusY: Global.notchRadius
          direction: PathArc.Counterclockwise
        }

        PathLine {
          x: 0; y: root.height - Global.notchRadius - Global.panelRadius
        }

        PathArc {
          x: Global.notchRadius; y: root.height - Global.panelRadius
          radiusX: Global.notchRadius; radiusY: Global.notchRadius
          direction: PathArc.Counterclockwise
        }
        PathLine {
          x: root.width - Global.panelRadius; y: root.height - Global.panelRadius
        }
        PathArc {
          x: root.width; y: root.height
          radiusX: Global.panelRadius; radiusY: Global.panelRadius
        }
      }
    }

    ColumnLayout {
      anchors.fill: parent
      anchors.leftMargin: Global.pad
      anchors.rightMargin: Global.pad
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
        value: AudioService.volume
        onMoved: AudioService.setVolume(value)
        onIconClicked: AudioService.toggleMute()
      }

      Slider {
        orientation: Slider.Vertical
        Layout.preferredHeight: root.sliderHeight
        Layout.preferredWidth: root.sliderWidth
        Layout.alignment: Qt.AlignHCenter
        from: 0; to: 1
        icon: "brightness_6"
        value: BrightnessService.brightness
        onMoved: BrightnessService.setBrightness(value)
      }
    }

    // ColumnLayout {
    //   anchors.fill: parent
    //   anchors.margins: root.Global.pad
    //   spacing: root.panelSpacing
    //
    //   Slider {
    //     orientation: Slider.Vertical
    //     Layout.preferredHeight: root.sliderHeight
    //     Layout.preferredWidth: root.sliderWidth
    //     Layout.alignment: Qt.AlignHCenter
    //     from: 0; to: 1
    //     icon: AudioService.muted ? "volume_off" : "volume_up"
    //     value: AudioService.volume
    //     onMoved: AudioService.setVolume(value)
    //     onIconClicked: AudioService.toggleMute()
    //   }
    //
    //   Slider {
    //     orientation: Slider.Vertical
    //     Layout.preferredHeight: root.sliderHeight
    //     Layout.preferredWidth: root.sliderWidth
    //     Layout.alignment: Qt.AlignHCenter
    //     from: 0; to: 1
    //     icon: "brightness_6"
    //     value: BrightnessService.brightness
    //     onMoved: BrightnessService.setBrightness(value)
    //   }
    // }
  }
}
