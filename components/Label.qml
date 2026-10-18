import QtQuick
import qs.common

Text {
  property string textColor: Theme.m3primary

  color: textColor
  font.family: Global.font || "Maven Pro"

  font.pixelSize: 13
  elide: Text.ElideRight
}
