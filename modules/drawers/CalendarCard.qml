import QtQuick
import QtQuick.Layouts

import Quickshell

import qs.common
import qs.components

Rectangle {
  id: root

  // 0 = Sunday, 1 = Monday ...
  property int weekStart: 1

  property int viewYear: 2000
  property int viewMonth: 0

  readonly property date today: clock.date
  readonly property bool viewingCurrentMonth:
    viewYear === today.getFullYear() && viewMonth === today.getMonth()
  readonly property int leadingDays:
    (new Date(viewYear, viewMonth, 1).getDay() - weekStart + 7) % 7

  color: Theme.m3surface_container_highest

  SystemClock {
    id: clock
    precision: SystemClock.Minutes
  }

  Component.onCompleted: goToday()

  function goToday(): void {
    viewYear = today.getFullYear()
    viewMonth = today.getMonth()
  }

  function shiftMonth(delta: int): void {
    const d = new Date(viewYear, viewMonth + delta, 1)
    viewYear = d.getFullYear()
    viewMonth = d.getMonth()
  }

  WheelHandler {
    acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
    onWheel: (e) => root.shiftMonth(e.angleDelta.y > 0 ? -1 : 1)
  }

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 14
    spacing: 4

    // ── Header: ‹  Month Year  › (fixed height) ──
    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: 32
      Layout.maximumHeight: 32

      Rectangle {
        id: prevBtn
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        width: 30; height: 30; radius: 15
        color: prevMouse.containsMouse ? Theme.m3surface_bright : "transparent"
        Icon {
          anchors.centerIn: parent
          text: "chevron_left"
          font.pixelSize: 22
          color: Theme.m3on_surface_variant
        }
        MouseArea {
          id: prevMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.shiftMonth(-1)
        }
      }

      Rectangle {
        id: nextBtn
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: 30; height: 30; radius: 15
        color: nextMouse.containsMouse ? Theme.m3surface_bright : "transparent"
        Icon {
          anchors.centerIn: parent
          text: "chevron_right"
          font.pixelSize: 22
          color: Theme.m3on_surface_variant
        }
        MouseArea {
          id: nextMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: root.shiftMonth(1)
        }
      }

      Item {
        anchors.left: prevBtn.right
        anchors.right: nextBtn.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        Label {
          anchors.centerIn: parent
          text: Qt.locale().monthName(root.viewMonth) + " " + root.viewYear
          font.pixelSize: 15
          font.bold: true
          color: Theme.m3on_surface
        }

        // click the title to jump back to today
        MouseArea {
          anchors.fill: parent
          cursorShape: root.viewingCurrentMonth ? Qt.ArrowCursor : Qt.PointingHandCursor
          onClicked: root.goToday()
        }
      }
    }

    // ── Weekday names (fixed height) ──
    Item {
      Layout.fillWidth: true
      Layout.preferredHeight: 18
      Layout.maximumHeight: 18

      Repeater {
        model: 7
        delegate: Item {
          required property int index
          x: index * (parent.width / 7)
          width: parent.width / 7
          height: parent.height
          Label {
            anchors.centerIn: parent
            text: Qt.locale().dayName((root.weekStart + index) % 7, Locale.ShortFormat).substring(0, 2)
            font.pixelSize: 12
            color: Theme.m3on_surface_variant
          }
        }
      }
    }

    // ── 6x7 day grid: takes ALL remaining height, cells sized explicitly ──
    Item {
      id: gridArea
      Layout.fillWidth: true
      Layout.fillHeight: true
      Layout.minimumHeight: 0

      readonly property real cellW: width / 7
      readonly property real cellH: height / 6

      Repeater {
        model: 42
        delegate: Item {
          id: cell
          required property int index
          readonly property date cellDate:
            new Date(root.viewYear, root.viewMonth, 1 - root.leadingDays + index)
          readonly property bool inMonth: cellDate.getMonth() === root.viewMonth
          readonly property bool isToday:
            cellDate.getFullYear() === root.today.getFullYear()
            && cellDate.getMonth() === root.today.getMonth()
            && cellDate.getDate() === root.today.getDate()

          x: (index % 7) * gridArea.cellW
          y: Math.floor(index / 7) * gridArea.cellH
          width: gridArea.cellW
          height: gridArea.cellH

          Rectangle {
            anchors.centerIn: parent
            width: Math.min(parent.width, parent.height) - 4
            height: width
            radius: width / 2
            color: cell.isToday
              ? Theme.m3primary
              : (cellMouse.containsMouse ? Theme.m3surface_bright : "transparent")

            Label {
              anchors.centerIn: parent
              text: cell.cellDate.getDate()
              font.pixelSize: 13
              font.bold: cell.isToday
              color: cell.isToday
                ? Theme.m3on_primary
                : (cell.inMonth ? Theme.m3on_surface : Qt.alpha(Theme.m3on_surface_variant, 0.45))
            }
          }

          MouseArea {
            id: cellMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: {
              // clicking a greyed-out day jumps to that month
              if (!cell.inMonth) {
                root.viewYear = cell.cellDate.getFullYear()
                root.viewMonth = cell.cellDate.getMonth()
              }
            }
          }
        }
      }
    }
  }
}
