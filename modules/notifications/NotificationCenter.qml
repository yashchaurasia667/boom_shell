import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell

import qs.common
import qs.components
import qs.services

ColumnLayout {
  id: panel
  // anchors {
  //   top: parent.top
  //   right: parent.right
  // }

  spacing: 8

  RowLayout {
    Layout.fillWidth: true
    // Layout.alignment: Qt.AlignRight
    // Layout.margins: Global.panelRadius

    Label {
      text: "Notifications"
      font.bold: true
      font.pixelSize: 16
      Layout.fillWidth: true
    }

    Label {
      visible: NotificationService.hasHistory
      text: NotificationService.historyCount
      color: Theme.m3on_surface
      font.pixelSize: 13
    }

    Rectangle {
      visible: NotificationService.hasHistory
      implicitWidth: clearLabel.implicitWidth + 16
      implicitHeight: clearLabel.implicitHeight + 8
      radius: 6
      color: Theme.m3surface_variant
      Layout.leftMargin: 8

      Label {
        id: clearLabel
        anchors.centerIn: parent
        text: "Clear all"
        font.pixelSize: 12
      }

      MouseArea {
        anchors.fill: parent
        onClicked: NotificationService.clearHistory()
      }
    }
  }

  ScrollView {
    Layout.fillWidth: true
    Layout.fillHeight: true
    clip: true

    ColumnLayout {
      width: panel.width
      spacing: 8

      Repeater {
        model: NotificationService.history
        delegate: NotificationHistoryTile {}
      }

      Label {
        visible: !NotificationService.hasHistory
        Layout.fillWidth: true
        Layout.topMargin: 40
        horizontalAlignment: Text.AlignHCenter
        text: "No notifications"
        color: Theme.m3on_surface
        font.pixelSize: 13
      }
    }
  }
}
