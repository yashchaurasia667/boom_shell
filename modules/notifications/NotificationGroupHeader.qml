import QtQuick
import QtQuick.Layouts

import qs.common
import qs.components

// Header row for a group of notifications from the same app.
Item {
  id: header

  required property string app
  required property int count
  required property bool expanded

  signal toggled()
  signal cleared()

  implicitHeight: 32

  MouseArea {
    anchors.fill: parent
    cursorShape: Qt.PointingHandCursor
    onClicked: header.toggled()
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 4
    anchors.rightMargin: 4
    spacing: 8

    Label {
      Layout.fillWidth: true
      text: header.app
      font.pixelSize: 13
      font.weight: 600
      textColor: Theme.m3on_surface
    }

    Rectangle {
      implicitWidth: Math.max(22, countLabel.implicitWidth + 12)
      implicitHeight: 20
      radius: 10
      color: Theme.m3secondary_container

      Label {
        id: countLabel
        anchors.centerIn: parent
        text: header.count
        font.pixelSize: 11
        font.weight: 600
        textColor: Theme.m3on_secondary_container
      }
    }

    Icon {
      text: header.expanded ? "expand_less" : "expand_more"
      font.pixelSize: 18
      color: Theme.m3on_surface_variant
    }

    Rectangle {
      implicitWidth: 24
      implicitHeight: 24
      radius: 12
      color: clearMouse.containsMouse ? Theme.m3surface_container_highest : "transparent"

      Behavior on color {
        ColorAnimation { duration: Global.dur.fast }
      }

      Icon {
        anchors.centerIn: parent
        text: "delete_sweep"
        font.pixelSize: 16
        color: Theme.m3on_surface_variant
      }

      MouseArea {
        id: clearMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: header.cleared()
      }
    }
  }
}
