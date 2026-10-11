import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.SystemTray

import qs.common
import qs.components

Item {
  id: root

  property bool expanded: false
  readonly property int iconSize: 20
  readonly property int iconSpacing: 8

  readonly property int trayContentWidth:
    SystemTray.items.values.length * iconSize +
    Math.max(0, SystemTray.items.values.length - 1) * iconSpacing

  // Let the internal Row dictate our width automatically. 
  // Added + 16 here to give a nice 8px padding on both left and right sides.
  implicitWidth: contentRow.width + 16 
  implicitHeight: Global.pillHeight - 12
  Layout.fillWidth: true

  Rectangle {
    anchors.fill: parent
    radius: Global.earRadius
    color: Theme.m3surface_variant
  }

  // A Row naturally handles the relative positioning without anchor swapping bugs
  Row {
    id: contentRow
    anchors.centerIn: parent // Keeps everything perfectly aligned inside the pill
    spacing: root.expanded ? root.iconSpacing : 0

    Behavior on spacing {
      NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
    }

    Item {
      id: trayContainer
      clip: true
      width: root.expanded ? root.trayContentWidth : 0
      height: root.iconSize
      anchors.verticalCenter: parent.verticalCenter

      Behavior on width {
        NumberAnimation { duration: 180; easing.type: Easing.OutCubic }
      }

      RowLayout {
        height: parent.height
        spacing: root.iconSpacing
        // Keep this anchored to the right so icons reveal nicely outward from the toggle
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

    // Static anchors - no dynamic swapping needed
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
