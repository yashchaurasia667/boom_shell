import QtQuick
import qs.common

Item {
  id: root

  enum Orientation { Horizontal, Vertical }
  property int orientation: Slider.Horizontal

  property real from: 0
  property real to: 1
  property real value: 0
  readonly property bool pressed: dragHandler.active || tapHandler.pressed

  property string icon: ""
  signal iconClicked()
  signal moved(real value)

  readonly property bool _horizontal: orientation === Slider.Horizontal

  implicitWidth: _horizontal ? 120 : 32
  implicitHeight: _horizontal ? 32 : 120

  Timer {
    id: hideDelay
    interval: Global.dur.slow
  }

  onValueChanged: hideDelay.restart()

  readonly property real _ratio: root.to > root.from
  ? Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from)))
  : 0

  function _setFromPos(pos: real): void {
    const size = root._horizontal ? track.width : track.height
    let ratio = Math.max(0, Math.min(1, pos / size))
    if (!root._horizontal) ratio = 1 - ratio

    const newValue = root.from + ratio * (root.to - root.from)
    root.value = newValue
    root.moved(newValue)
  }

  Rectangle {
    id: track
    anchors.fill: parent
    radius: (root._horizontal ? height : width) / 2
    color: Theme.m3surface_variant
    clip: true

    Rectangle {
      id: fill
      radius: track.radius
      color: Theme.m3primary

      anchors.left: root._horizontal ? parent.left : undefined
      anchors.top: root._horizontal ? parent.top : undefined
      anchors.bottom: parent.bottom
      anchors.right: root._horizontal ? undefined : parent.right

      width: root._horizontal ? parent.width * root._ratio : parent.width
      height: root._horizontal ? parent.height : parent.height * root._ratio
    }

    Icon {
      id: iconLabel
      visible: root.icon !== "" && !root.pressed && !hideDelay.running
      text: root.icon
      font.pixelSize: 16
      color: {
        const fillExtent = root._horizontal ? root._ratio * track.width : root._ratio * track.height
        const iconPos = root._horizontal ? width + 20 : height + 20
        return fillExtent > iconPos ? Theme.m3on_primary : Theme.m3on_surface
      }

      anchors.left: root._horizontal ? parent.left : undefined
      anchors.leftMargin: root._horizontal ? 10 : 0
      anchors.verticalCenter: root._horizontal ? parent.verticalCenter : undefined
      anchors.bottom: root._horizontal ? undefined : parent.bottom
      anchors.bottomMargin: root._horizontal ? 0 : 10
      anchors.horizontalCenter: root._horizontal ? undefined : parent.horizontalCenter

      TapHandler { onTapped: root.iconClicked() }
    }

    Label {
      visible: root.pressed || hideDelay.running
      text: Math.round(root._ratio * 100) + "%"
      font.bold: true
      font.pixelSize: 13
      color: iconLabel.color

      anchors.left: root._horizontal ? parent.left : undefined
      anchors.leftMargin: root._horizontal ? 10 : 0
      anchors.verticalCenter: root._horizontal ? parent.verticalCenter : undefined
      anchors.bottom: root._horizontal ? undefined : parent.bottom
      anchors.bottomMargin: root._horizontal ? 0 : 10
      anchors.horizontalCenter: root._horizontal ? undefined : parent.horizontalCenter
    }

    TapHandler {
      id: tapHandler
      onTapped: (eventPoint) => {
        const pos = root._horizontal ? eventPoint.position.x : eventPoint.position.y
        root._setFromPos(pos)
      }
    }

    DragHandler {
      id: dragHandler
      target: null
      xAxis.minimum: 0
      xAxis.maximum: root._horizontal ? track.width : 0
      yAxis.minimum: 0
      yAxis.maximum: root._horizontal ? 0 : track.height

      onCentroidChanged: {
        if (!active) return
        const pos = root._horizontal ? centroid.position.x : centroid.position.y
        root._setFromPos(pos)
      }
    }

    MouseArea {
      id: wheelHandler
      anchors.fill: parent
      acceptedButtons: Qt.NoButton
      onWheel: (event) => {
        const step = (root.to - root.from) * 0.05
        const rawDelta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y
        const delta = rawDelta > 0 ? step : -step
        const newValue = Math.max(root.from, Math.min(root.to, root.value + delta))
        root.value = newValue
        root.moved(newValue)
      }
    }
  }
}
