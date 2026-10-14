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
      id: historyColumn
      width: panel.width
      spacing: 8

      // Group notifications by title. Order of first appearance is preserved,
      // and each group's notifications are kept in their original order.
      property var groupedHistory: {
        const groups = [];
        const groupsByTitle = {};

        for (const notif of NotificationService.history) {
          const key = notif.summary;

          if (!groupsByTitle[key]) {
            groupsByTitle[key] = { summary: key, notifications: [] };
            groups.push(groupsByTitle[key]);
          }

          groupsByTitle[key].notifications.push(notif);
        }

        return groups;
      }

      Repeater {
        model: historyColumn.groupedHistory

        delegate: ColumnLayout {
          id: groupDelegate
          required property var modelData

          // collapsed groups show only the latest notification + a count badge;
          // tapping the header reveals the rest
          property bool expanded: false
          property bool isGroup: modelData.notifications.length > 1

          Layout.fillWidth: true
          spacing: 4

          RowLayout {
            Layout.fillWidth: true
            visible: groupDelegate.isGroup

            Label {
              text: groupDelegate.modelData.summary
              font.bold: true
              font.pixelSize: 13
              color: Theme.m3on_surface
              Layout.fillWidth: true
            }

            Rectangle {
              implicitWidth: countLabel.implicitWidth + 12
              implicitHeight: countLabel.implicitHeight + 4
              radius: 8
              color: Theme.m3surface_variant

              Label {
                id: countLabel
                anchors.centerIn: parent
                text: groupDelegate.modelData.notifications.length
                font.pixelSize: 11
                color: Theme.m3on_surface
              }
            }

            Icon {
              text: groupDelegate.expanded ? "expand_less" : "expand_more"
              font.pixelSize: 16
              color: Theme.m3on_surface
            }

            MouseArea {
              // anchors.fill: parent
              Layout.fillWidth: true
              Layout.fillHeight: true
              onClicked: groupDelegate.expanded = !groupDelegate.expanded
            }
          }

          Repeater {
            // collapsed: just the newest notification in the group
            // expanded (or singleton groups): every notification
            model: groupDelegate.isGroup && !groupDelegate.expanded
              ? [groupDelegate.modelData.notifications[0]]
              : groupDelegate.modelData.notifications
            delegate: NotificationHistoryTile {}
          }
        }
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
