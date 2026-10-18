import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

import qs.common
import qs.components

Item {
  id: root

  property bool expanded: Global.trayStartExpanded
  readonly property int iconSize: Global.trayIconSize
  readonly property int iconSpacing: Global.trayIconSpacing

  readonly property int trayContentWidth:
    SystemTray.items.values.length * iconSize +
    Math.max(0, SystemTray.items.values.length - 1) * iconSpacing

  implicitWidth: contentRow.width + 16
  implicitHeight: Global.pillHeight - 12
  Layout.fillWidth: true

  Rectangle {
    anchors.fill: parent
    radius: Global.earRadius
    color: Theme.m3surface_variant
  }

  Row {
    id: contentRow
    anchors.centerIn: parent
    spacing: root.expanded ? root.iconSpacing : 0

    Behavior on spacing {
      Anim {}
    }

    Item {
      id: trayContainer
      clip: true
      visible: width > 0
      width: root.expanded ? root.trayContentWidth : 0
      height: root.iconSize
      anchors.verticalCenter: parent.verticalCenter

      Behavior on width {
        Anim {}
      }

      RowLayout {
        height: parent.height
        spacing: root.iconSpacing
        anchors.right: parent.right

        Repeater {
          model: SystemTray.items

          delegate: Item {
            id: trayIcon
            required property SystemTrayItem modelData

            implicitWidth: root.iconSize
            implicitHeight: root.iconSize

            Image {
              anchors.fill: parent
              source: trayIcon.modelData.icon
              sourceSize: Qt.size(root.iconSize, root.iconSize)
              asynchronous: true
              fillMode: Image.PreserveAspectFit
            }

            MouseArea {
              anchors.fill: parent
              acceptedButtons: Qt.LeftButton | Qt.RightButton

              onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton) {
                  trayIcon.modelData.activate()
                } else if (mouse.button === Qt.RightButton) {
                  if (trayIcon.modelData.hasMenu) {
                    menuAnchor.menu = trayIcon.modelData.menu
                    menuAnchor.open()
                  }
                }
              }
            }

            QsMenuAnchor {
              id: menuAnchor
              anchor.window: trayIcon.QsWindow.window
              anchor.item: trayIcon
              anchor.rect.y: trayIcon.height
            }
          }
        }
      }
    }

    Icon {
      id: toggleIcon
      anchors.verticalCenter: parent.verticalCenter
      text: root.expanded ? "chevron_right" : "chevron_left"
      font.pixelSize: 16
      color: Theme.m3primary

      MouseArea {
        anchors.fill: parent
        onClicked: root.expanded = !root.expanded
      }
    }
  }
}
