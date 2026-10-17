import QtQuick
import QtQuick.Controls

import qs.common

Button {
  id: root

  // Custom exposed properties
  property color baseColor: Theme.m3primary
  property color hoverColor: Theme.m3primary_fixed
  property color pressColor: Theme.m3primary_container
  property color textColor: Theme.m3surface

  property string btnFont: Global.font
  property int fontSize: Global.fontSize

  property int borderWidth: 2
  property color borderColor: Theme.m3primary
  property int cornerRadius: 8

  implicitWidth: 120
  implicitHeight: 38
  hoverEnabled: true

  contentItem: Text {
    text: root.text
    font.family: root.btnFont
    font.pixelSize: root.fontSize
    font.weight: Font.Medium
    color: root.textColor
    horizontalAlignment: Text.AlignHCenter
    verticalAlignment: Text.AlignVCenter
  }

  background: Rectangle {
    radius: root.cornerRadius
    color: root.down ? root.pressColor : (root.hovered ? root.hoverColor : root.baseColor)

    border.width: root.borderWidth
    border.color: root.borderColor

    Behavior on color {
      ColorAnimation { duration: Global.dur.fast }
    }
  }

  scale: root.down ? 0.95 : (root.hovered ? 1.05 : 1.0)
  transformOrigin: Item.Center

  Behavior on scale {
    Anim {}
  }
}
