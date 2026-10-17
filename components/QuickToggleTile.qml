import QtQuick
import QtQuick.Layouts

import qs.common
import qs.components

Rectangle {
  id: tile

  property string icon: ""
  property string title: ""
  property string subtitle: ""
  property bool active: false
  property bool showChevron: false

  // Theme colors (customizable per instance)
  property color cardColor: Theme.m3surface_container_highest
  property color hoverCardColor: Theme.m3surface_bright
  property color badgeHoverColor: Theme.m3surface_variant
  property color activeColor: Theme.m3primary
  property color activeContentColor: Theme.m3surface
  property color textPrimary: Theme.m3on_primary_container
  property color textSecondary: Theme.m3on_surface_variant

  signal clicked()
  signal iconToggled()

  implicitWidth: 158
  implicitHeight: 88
  radius: 20

  color: tile.active
    ? (tileMouse.containsMouse ? Qt.darker(tile.activeColor, 1.06) : tile.activeColor)
    : (tileMouse.containsMouse ? tile.hoverCardColor : tile.cardColor)

  Behavior on color {
    ColorAnimation { duration: Global.dur.fast }
  }

  // Clicking the card body opens the expanded view (or triggers main action)
  MouseArea {
    id: tileMouse
    anchors.fill: parent
    hoverEnabled: true
    cursorShape: Qt.PointingHandCursor
    onClicked: tile.clicked()
  }

  RowLayout {
    anchors.fill: parent
    anchors.leftMargin: 14
    anchors.rightMargin: 14
    spacing: 10

    // Clicking the icon badge toggles power directly
    Rectangle {
      Layout.preferredWidth: 34
      Layout.preferredHeight: 34
      radius: 17
      color: iconMouse.containsMouse
        ? (tile.active
            ? Qt.rgba(tile.activeContentColor.r, tile.activeContentColor.g, tile.activeContentColor.b, 0.12)
            : tile.badgeHoverColor)
        : "transparent"

      Icon {
        anchors.centerIn: parent
        text: tile.icon
        font.pixelSize: 22
        color: tile.active ? tile.activeContentColor : tile.textPrimary
      }

      MouseArea {
        id: iconMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: tile.iconToggled()
      }
    }

    ColumnLayout {
      Layout.fillWidth: true
      spacing: 1

      Label {
        Layout.fillWidth: true
        text: tile.title
        font.bold: true
        font.pixelSize: 14
        color: tile.active ? tile.activeContentColor : tile.textPrimary
        elide: Text.ElideRight
      }

      Label {
        Layout.fillWidth: true
        text: tile.subtitle
        font.pixelSize: 12
        color: tile.active
          ? Qt.rgba(tile.activeContentColor.r, tile.activeContentColor.g, tile.activeContentColor.b, 0.75)
          : tile.textSecondary
        elide: Text.ElideRight
      }
    }

    Icon {
      visible: tile.showChevron
      text: "chevron_right"
      font.pixelSize: 18
      color: tile.active
        ? Qt.rgba(tile.activeContentColor.r, tile.activeContentColor.g, tile.activeContentColor.b, 0.75)
        : tile.textSecondary
    }
  }
}
