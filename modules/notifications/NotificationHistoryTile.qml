import QtQuick
import QtQuick.Layouts

import qs.common
import qs.components
import qs.services

Rectangle {
  id: tile
  required property var modelData   // plain {id, summary, body, image, appIcon, appName, timestamp}

  Layout.fillWidth: true
  implicitHeight: content.implicitHeight + 24
  radius: 12
  color: Theme.m3surface
  border.color: Theme.m3surface_variant
  border.width: 1

  RowLayout {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.margins: 12
    spacing: 10

    Image {
      visible: tile.modelData.image !== ""
      source: tile.modelData.image
      Layout.preferredWidth: 36
      Layout.preferredHeight: 36
      fillMode: Image.PreserveAspectCrop
    }

    Icon {
      visible: tile.modelData.image === ""
      text: "notifications"
      font.pixelSize: 20
      color: Theme.m3primary
    }

    ColumnLayout {
      Layout.fillWidth: true
      // anchors {}
      spacing: 2

      Label {
        Layout.fillWidth: true
        text: tile.modelData.summary
        font.bold: true
        font.pixelSize: 14
        elide: Text.ElideRight
      }

      Label {
        Layout.fillWidth: true
        visible: tile.modelData.body !== ""
        text: tile.modelData.body
        font.pixelSize: 12
        color: Theme.m3on_surface
        wrapMode: Text.WordWrap
        maximumLineCount: 3
        elide: Text.ElideRight
      }
    }

    Icon {
      text: "close"
      font.pixelSize: 14
      color: Theme.m3error

      MouseArea {
        anchors.fill: parent
        onClicked: NotificationService.removeFromHistory(tile.modelData.id)
      }
    }
  }
}
