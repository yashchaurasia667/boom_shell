import QtQuick
import QtQuick.Layouts
import Quickshell.Hyprland

import qs.common
import qs.components

Item {
  readonly property var ws: Hyprland.workspaces
  readonly property var focusedWs: Hyprland.focusedWorkspace
  readonly property int minSlots: 4

  property string openSpecialName: ""

  readonly property bool anySpecialActive: openSpecialName !== ""

  Connections {
    target: Hyprland
    function onRawEvent(event) {
      if (event.name === "activespecial") {
        openSpecialName = event.data.split(",")[0]
      }
    }
  }

  readonly property var specialSlots: {
    const specials = Hyprland.workspaces.values
      .filter(w => w.id < 0 && w.name.startsWith("special:"))
    return specials.map(w => ({
      id: w.id,
      label: w.name.replace(/^special:/, ""),
      active: w.name === openSpecialName
    }))
  }

  height: Global.pillHeight
  Layout.alignment: Qt.AlignLeft
  // Layout.leftMargin: Global.pad

  RowLayout {
    anchors.fill: parent
    spacing: 10

    Repeater {
      model: {
        const occupiedIds = Hyprland.workspaces.values
          .filter(w => w.id > 0 && w.toplevels.values.length > 0)
          .map(w => w.id)
        return [...new Set([1, 2, 3, 4, ...occupiedIds])].sort((a, b) => a - b)
      }

      delegate: Rectangle {
        id: wsTile
        required property int modelData
        property bool focused: focusedWs && focusedWs.id === modelData && !anySpecialActive

        height: Global.pillHeight - 15
        implicitWidth: Global.pillHeight - 15

        color: focused ? Theme.m3source_color: Theme.m3surface_variant
        radius: focused ? wsTile.height/2 :  6

        // Behavior on color { ColorAnimation { duration: 150 } }
        Behavior on radius {
          NumberAnimation {
            duration: 150
          }
        }

        Text {
          anchors.centerIn: parent
          text: modelData
          color: focused ? Theme.m3surface : Theme.m3on_surface
          font.family: Global.font
          font.bold: focused ? true : false
          font.pixelSize: Global.fontSize
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Hyprland.dispatch("hl.dsp.focus({ workspace = " + modelData + " })")
        }

      }
    }

    Rectangle {
      visible: specialSlots.length > 0
      Layout.preferredWidth: 1
      Layout.fillHeight: true
      color: Theme.m3surface_variant
    }

    Repeater {
      model: specialSlots

      delegate: Rectangle {
        required property var modelData

        height: Global.pillHeight - 15
        implicitWidth: label.implicitWidth + 16

        color: modelData.active ? Theme.m3tertiary : Theme.m3surface_variant
        radius: 6

        Text {
          id: label
          anchors.centerIn: parent
          text: modelData.label
          color: modelData.active ? Theme.m3surface : Theme.m3on_surface
          font.family: Global.font
          font.weight: modelData.active ? 600 : 500
          font.pixelSize: Global.fontSize
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: Hyprland.dispatch('hl.dsp.workspace.toggle_special("' + modelData.label + '")')
        }
      }
    }
  }
}
