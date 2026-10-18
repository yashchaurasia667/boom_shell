import QtQuick
import QtQuick.Layouts

import Quickshell

import qs.common
import qs.components
import qs.services

Rectangle {
  id: tile

  required property var modelData   // plain {id, summary, body, image, appIcon, appName, urgency, timestamp}
  property real now: Date.now()     // bumped by the parent so the age label stays fresh
  property bool showApp: true

  readonly property string appIconPath: modelData.appIcon ? Quickshell.iconPath(modelData.appIcon, true) : ""
  readonly property bool hasImage: modelData.image !== ""

  implicitHeight: content.implicitHeight + 24
  radius: 14
  color: hover.hovered ? Theme.m3surface_container_high : Theme.m3surface_container

  Behavior on color {
    ColorAnimation { duration: Global.dur.fast }
  }

  function age(ts: real): string {
    const s = Math.max(0, Math.floor((tile.now - ts) / 1000))
    if (s < 60) return "now"
    if (s < 3600) return Math.floor(s / 60) + "m"
    if (s < 86400) return Math.floor(s / 3600) + "h"
    return Math.floor(s / 86400) + "d"
  }

  HoverHandler {
    id: hover
  }

  RowLayout {
    id: content
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.verticalCenter: parent.verticalCenter
    anchors.margins: 12
    spacing: 12

    // image / app icon / fallback bell
    Item {
      Layout.preferredWidth: 40
      Layout.preferredHeight: 40
      Layout.alignment: Qt.AlignTop

      Image {
        anchors.fill: parent
        visible: tile.hasImage
        source: tile.hasImage ? tile.modelData.image : ""
        sourceSize: Qt.size(80, 80)
        asynchronous: true
        cache: false
        fillMode: Image.PreserveAspectCrop
      }

      Image {
        anchors.fill: parent
        anchors.margins: 4
        visible: !tile.hasImage && tile.appIconPath !== ""
        source: tile.appIconPath
        sourceSize: Qt.size(64, 64)
        asynchronous: true
        fillMode: Image.PreserveAspectFit
      }

      Rectangle {
        anchors.fill: parent
        visible: !tile.hasImage && tile.appIconPath === ""
        radius: 20
        color: tile.modelData.urgency === 2 ? Theme.m3error_container : Theme.m3primary_container

        Icon {
          anchors.centerIn: parent
          text: tile.modelData.urgency === 2 ? "priority_high" : "notifications"
          font.pixelSize: 20
          color: tile.modelData.urgency === 2 ? Theme.m3on_error_container : Theme.m3on_primary_container
        }
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 2

      RowLayout {
        Layout.fillWidth: true
        spacing: 6

        Label {
          visible: tile.showApp && tile.modelData.appName !== ""
          text: tile.modelData.appName
          font.pixelSize: 11
          font.weight: 600
          textColor: Theme.m3primary
        }

        Label {
          Layout.fillWidth: true
          text: (tile.showApp && tile.modelData.appName !== "" ? "·  " : "") + tile.age(tile.modelData.timestamp)
          font.pixelSize: 11
          textColor: Theme.m3on_surface_variant
        }
      }

      Label {
        Layout.fillWidth: true
        text: tile.modelData.summary
        font.pixelSize: 14
        font.weight: 600
        textColor: Theme.m3on_surface
        elide: Text.ElideRight
      }

      Label {
        Layout.fillWidth: true
        visible: tile.modelData.body !== ""
        text: tile.modelData.body
        font.pixelSize: 12
        textColor: Theme.m3on_surface_variant
        wrapMode: Text.WordWrap
        maximumLineCount: 3
        elide: Text.ElideRight
      }
    }

    Rectangle {
      Layout.alignment: Qt.AlignTop
      implicitWidth: 24
      implicitHeight: 24
      radius: 12
      color: closeMouse.containsMouse ? Theme.m3surface_container_highest : "transparent"
      opacity: hover.hovered ? 1 : 0

      Behavior on opacity {
        NumberAnimation { duration: Global.dur.fast }
      }
      Behavior on color {
        ColorAnimation { duration: Global.dur.fast }
      }

      Icon {
        anchors.centerIn: parent
        text: "close"
        font.pixelSize: 15
        color: Theme.m3on_surface_variant
      }

      MouseArea {
        id: closeMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: NotificationService.removeFromHistory(tile.modelData.id)
      }
    }
  }
}
