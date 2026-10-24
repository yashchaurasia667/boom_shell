import QtQuick

import qs.common
import qs.services

// Small audio visualizer; only exists (and only runs cava) while media is playing.
Item {
  id: root

  readonly property bool active: MprisService.playing
  property int barWidth: 3
  property int barSpacing: 2
  property int maxHeight: 18
  property int minHeight: 3

  readonly property real fullWidth: CavaService.barCount * barWidth + (CavaService.barCount - 1) * barSpacing

  implicitWidth: active ? fullWidth : 0
  implicitHeight: maxHeight
  opacity: active ? 1 : 0
  clip: true

  Behavior on implicitWidth { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
  Behavior on opacity { NumberAnimation { duration: 180 } }

  // request cava data only while visible
  onActiveChanged: CavaService.users += active ? 1 : -1
  Component.onCompleted: if (active) CavaService.users += 1
  Component.onDestruction: if (active) CavaService.users -= 1

  Row {
    anchors.verticalCenter: parent.verticalCenter
    spacing: root.barSpacing

    Repeater {
      model: CavaService.barCount

      Rectangle {
        required property int index
        readonly property real v: CavaService.values[index] ?? 0

        width: root.barWidth
        radius: width / 2
        height: root.minHeight + v * (root.maxHeight - root.minHeight)
        anchors.verticalCenter: parent.verticalCenter
        color: Theme.m3primary
        opacity: 0.55 + 0.45 * v

        Behavior on height { NumberAnimation { duration: 70 } }
      }
    }
  }
}
