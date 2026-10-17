import QtQuick
import QtQuick.Layouts

import qs.common
import qs.components

ColumnLayout {
  id: cal
  spacing: 8

  property date viewDate: new Date()
  readonly property int viewYear: viewDate.getFullYear()
  readonly property int viewMonth: viewDate.getMonth()
  readonly property date today: new Date()

  function shiftMonth(delta: int): void {
    viewDate = new Date(viewYear, viewMonth + delta, 1)
  }

  RowLayout {
    // Layout.fillWidth: true
    Layout.bottomMargin: Global.pad

    Icon {
      text: "chevron_left"
      font.pixelSize: 22
      MouseArea { anchors.fill: parent; onClicked: cal.shiftMonth(-1) }
    }

    Label {
      Layout.fillWidth: true
      font.pixelSize: 16
      horizontalAlignment: Text.AlignHCenter
      font.bold: true
      text: Qt.formatDate(cal.viewDate, "MMMM yyyy")
    }

    Icon {
      text: "chevron_right"
      font.pixelSize: 22
      MouseArea { anchors.fill: parent; onClicked: cal.shiftMonth(1) }
    }
  }

  GridLayout {
    Layout.fillWidth: true
    Layout.alignment: Qt.AlignHCenter
    columns: 7
    rowSpacing: 4
    columnSpacing: 4

    Repeater {
      model: ["S", "M", "T", "W", "T", "F", "S"]
      delegate: Label {
        Layout.preferredWidth: 30
        horizontalAlignment: Text.AlignHCenter
        text: modelData
        color: Theme.m3on_surface
        font.pixelSize: 14
      }
    }

    Repeater {
      model: {
        const firstOfMonth = new Date(cal.viewYear, cal.viewMonth, 1)
        const startOffset = firstOfMonth.getDay()
        const daysInMonth = new Date(cal.viewYear, cal.viewMonth + 1, 0).getDate()

        const cells = []
        for (let i = 0; i < startOffset; i++) cells.push(null)
        for (let d = 1; d <= daysInMonth; d++) cells.push(d)
        return cells
      }

      delegate: Rectangle {
        required property var modelData
        Layout.preferredWidth: 30
        Layout.preferredHeight: 30
        radius: 14
        color: {
          if (modelData === null) return "transparent"
          const isToday = modelData === cal.today.getDate()
            && cal.viewMonth === cal.today.getMonth()
            && cal.viewYear === cal.today.getFullYear()
          return isToday ? Theme.m3primary : "transparent"
        }

        Label {
          anchors.centerIn: parent
          visible: parent.modelData !== null
          text: parent.modelData ?? ""
          font.pixelSize: 16
        }
      }
    }
  }
}
