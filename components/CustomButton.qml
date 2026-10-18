import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import qs.common

Button {
  id: root

  property color baseColor: Theme.m3primary
  property color hoverColor: Theme.m3primary_fixed
  property color pressColor: Theme.m3primary_container
  property color textColor: Theme.m3on_primary
  property string btnFont: Global.font || "Maven Pro"

  property int fontSize: Global.fontSize
  property int borderWidth: 0
  property color borderColor: Theme.m3primary

  property int cornerRadius: 8

  default property alias contentChildren: contentLayout.children

  implicitWidth: 120
  implicitHeight: 38
  hoverEnabled: true

  contentItem: RowLayout {
    id: contentLayout
    spacing: 8
    Layout.alignment: Qt.AlignCenter

    Text {
      id: fallbackText
      text: root.text
      font.family: root.btnFont || "Maven Pro"
      font.pixelSize: root.fontSize
      font.weight: Font.Medium
      color: root.textColor
      horizontalAlignment: Text.AlignHCenter
      verticalAlignment: Text.AlignVCenter
      visible: text !== "" && contentLayout.children.length === 1
      Layout.alignment: Qt.AlignCenter
    }
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
}
