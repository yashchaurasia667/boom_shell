import QtQuick
import qs.common

Item {
  id: root

  enum Orientation { Horizontal, Vertical }
  property int orientation: Slider.Horizontal
  property int iconSize: Global.fontSize
  property int fontSize: Global.fontSize

  property real from: 0
  property real to: 1
  property real value: 0
  readonly property bool pressed: dragHandler.active || tapHandler.pressed

  // ── Appearance & Color Customization ──
  property color trackColor: Theme.m3surface_variant
  property color fillColor: Theme.m3primary

  property color activeIconColor: Theme.m3on_primary         // icon/text color when covered by fill
  property color inactiveIconColor: Theme.m3on_surface    // icon/text color when on empty track

  property color iconColor: "transparent"                 // set to a solid color to override auto-contrast
  property color textColor: "transparent"                 // set to a solid color to override label color
  property color borderColor: "transparent"
  property int borderWidth: 0

  // ── Geometry & Behavior Customization ──
  property real trackRadius: -1                           // -1 = automatic full pill radius
  property real fillRadius: -1                            // -1 = match trackRadius
  property int iconMargin: 10                             // left margin (horizontal) or bottom margin (vertical)
  property real wheelStep: 0.05                           // scroll step as a fraction of (to - from)
  property bool showPercentage: true                      // show percentage readout on change/drag
  property bool animateFill: false                        // optional smooth animation on fill resize

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

  onValueChanged: {
    if (root.showPercentage) hideDelay.restart()
  }

  readonly property real _ratio: root.to > root.from
    ? Math.max(0, Math.min(1, (root.value - root.from) / (root.to - root.from)))
    : 0

  readonly property color _autoContrastColor: {
    const fillExtent = root._horizontal ? root._ratio * track.width : root._ratio * track.height
    const iconPos = (root._horizontal ? iconLabel.width : iconLabel.height) + root.iconMargin * 2
    return fillExtent > iconPos ? root.activeIconColor : root.inactiveIconColor
  }

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
    radius: root.trackRadius >= 0 ? root.trackRadius : (root._horizontal ? height : width) / 2
    color: root.trackColor
    border.color: root.borderColor
    border.width: root.borderWidth
    clip: true

    Rectangle {
      id: fill
      radius: root.fillRadius >= 0 ? root.fillRadius : track.radius
      color: root.fillColor

      anchors.left: root._horizontal ? parent.left : undefined
      anchors.top: root._horizontal ? parent.top : undefined
      anchors.bottom: parent.bottom
      anchors.right: root._horizontal ? undefined : parent.right

      width: root._horizontal ? parent.width * root._ratio : parent.width
      height: root._horizontal ? parent.height : parent.height * root._ratio

      Behavior on width {
        enabled: root.animateFill && root._horizontal
        Anim {}
      }

      Behavior on height {
        enabled: root.animateFill && !root._horizontal
        Anim {}
      }
    }

    Icon {
      id: iconLabel
      visible: root.icon !== "" && (!root.showPercentage || (!root.pressed && !hideDelay.running))
      text: root.icon
      font.pixelSize: root.iconSize
      color: root.iconColor.a > 0 ? root.iconColor : root._autoContrastColor

      anchors.left: root._horizontal ? parent.left : undefined
      anchors.leftMargin: root._horizontal ? root.iconMargin : 0
      anchors.verticalCenter: root._horizontal ? parent.verticalCenter : undefined
      anchors.bottom: root._horizontal ? undefined : parent.bottom
      anchors.bottomMargin: root._horizontal ? 0 : root.iconMargin
      anchors.horizontalCenter: root._horizontal ? undefined : parent.horizontalCenter

      TapHandler { onTapped: root.iconClicked() }
    }

    Label {
      visible: root.showPercentage && (root.pressed || hideDelay.running)
      text: Math.round(root._ratio * 100) + "%"
      font.bold: true
      font.pixelSize: root.fontSize
      color: root.textColor.a > 0 ? root.textColor : iconLabel.color

      anchors.left: root._horizontal ? parent.left : undefined
      anchors.leftMargin: root._horizontal ? root.iconMargin : 0
      anchors.verticalCenter: root._horizontal ? parent.verticalCenter : undefined
      anchors.bottom: root._horizontal ? undefined : parent.bottom
      anchors.bottomMargin: root._horizontal ? 0 : root.iconMargin
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
        const step = (root.to - root.from) * root.wheelStep
        const rawDelta = event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y
        const delta = rawDelta > 0 ? step : -step
        const newValue = Math.max(root.from, Math.min(root.to, root.value + delta))
        root.value = newValue
        root.moved(newValue)
      }
    }
  }
}
