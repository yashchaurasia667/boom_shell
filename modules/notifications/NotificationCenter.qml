import QtQuick
import QtQuick.Layouts
import Quickshell

import qs.common
import qs.components
import qs.services

ColumnLayout {
  id: panel
  spacing: 10

  // which app groups are expanded; kept here (not in delegates) so it survives list updates
  property var expandedApps: ({})
  property real now: Date.now()

  function toggleApp(app: string): void {
    const next = Object.assign({}, panel.expandedApps)
    next[app] = !next[app]
    panel.expandedApps = next
  }

  Timer {
    interval: 30000
    running: true
    repeat: true
    onTriggered: panel.now = Date.now()
  }

  // Group history by app. Header rows are only emitted for groups with 2+ entries,
  // collapsed groups show just their newest entry.
  // Item rows reuse the original history entry objects, so ScriptModel can keep delegates alive.
  readonly property var layoutData: {
    const order = []
    const map = {}
    for (const e of NotificationService.history) {
      const k = e.appName || "Other"
      if (!map[k]) { map[k] = []; order.push(k) }
      map[k].push(e)
    }

    const rows = []
    const counts = {}
    for (const k of order) {
      const list = map[k]
      counts[k] = list.length
      if (list.length > 1) rows.push({ rowId: "h:" + k, kind: "header", app: k })
      const shown = list.length > 1 && !panel.expandedApps[k] ? list.slice(0, 1) : list
      for (const e of shown) rows.push({ rowId: "n:" + e.id, kind: "item", app: k, entry: e })
    }
    return { rows: rows, counts: counts }
  }

  // ── header ──
  RowLayout {
    Layout.fillWidth: true
    spacing: 8

    Label {
      text: "Notifications"
      font.pixelSize: 17
      font.weight: 600
      textColor: Theme.m3on_surface
    }

    Rectangle {
      visible: NotificationService.hasHistory
      implicitWidth: Math.max(22, countLabel.implicitWidth + 12)
      implicitHeight: 20
      radius: 10
      color: Theme.m3secondary_container

      Label {
        id: countLabel
        anchors.centerIn: parent
        text: NotificationService.historyCount
        font.pixelSize: 11
        font.weight: 600
        textColor: Theme.m3on_secondary_container
      }
    }

    Item { Layout.fillWidth: true }

    // Do Not Disturb toggle
    Rectangle {
      implicitWidth: 34
      implicitHeight: 34
      radius: NotificationService.doNotDisturb ? 12 : 17
      color: NotificationService.doNotDisturb
        ? Theme.m3primary
        : (dndMouse.containsMouse ? Theme.m3surface_container_highest : Theme.m3surface_container_high)

      Behavior on color {
        ColorAnimation { duration: Global.dur.fast }
      }
      Behavior on radius {
        Anim {}
      }

      Icon {
        anchors.centerIn: parent
        text: NotificationService.doNotDisturb ? "notifications_off" : "notifications_active"
        font.pixelSize: 18
        color: NotificationService.doNotDisturb ? Theme.m3on_primary : Theme.m3on_surface_variant
      }

      MouseArea {
        id: dndMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: NotificationService.toggleDoNotDisturb()
      }
    }

    // Clear all
    Rectangle {
      implicitWidth: clearRow.implicitWidth + 24
      implicitHeight: 34
      radius: 17
      color: clearMouse.containsMouse ? Theme.m3surface_container_highest : Theme.m3surface_container_high
      opacity: NotificationService.hasHistory ? 1 : 0.4

      Behavior on color {
        ColorAnimation { duration: Global.dur.fast }
      }

      RowLayout {
        id: clearRow
        anchors.centerIn: parent
        spacing: 6

        Icon {
          text: "delete_sweep"
          font.pixelSize: 16
          color: Theme.m3on_surface_variant
        }

        Label {
          text: "Clear"
          font.pixelSize: 12
          font.weight: 500
          textColor: Theme.m3on_surface_variant
        }
      }

      MouseArea {
        id: clearMouse
        anchors.fill: parent
        hoverEnabled: true
        enabled: NotificationService.hasHistory
        cursorShape: Qt.PointingHandCursor
        onClicked: NotificationService.clearHistory()
      }
    }
  }

  // ── Do Not Disturb banner ──
  Rectangle {
    Layout.fillWidth: true
    Layout.preferredHeight: NotificationService.doNotDisturb ? 40 : 0
    opacity: NotificationService.doNotDisturb ? 1 : 0
    visible: Layout.preferredHeight > 0.5
    clip: true
    radius: 14
    color: Theme.m3secondary_container

    Behavior on Layout.preferredHeight {
      Anim { curve: Global.smooth }
    }
    Behavior on opacity {
      NumberAnimation { duration: Global.dur.fast }
    }

    RowLayout {
      anchors.fill: parent
      anchors.leftMargin: 14
      anchors.rightMargin: 14
      spacing: 8

      Icon {
        text: "do_not_disturb_on"
        font.pixelSize: 18
        color: Theme.m3on_secondary_container
      }

      Label {
        Layout.fillWidth: true
        text: NotificationService.missedCount > 0
          ? "Do Not Disturb · " + NotificationService.missedCount + " silenced"
          : "Do Not Disturb is on"
        font.pixelSize: 12
        font.weight: 500
        textColor: Theme.m3on_secondary_container
      }
    }
  }

  // ── list ──
  Item {
    Layout.fillWidth: true
    Layout.fillHeight: true

    ListView {
      id: list
      anchors.fill: parent
      clip: true
      spacing: 8
      boundsBehavior: Flickable.StopAtBounds

      model: ScriptModel {
        values: panel.layoutData.rows
        objectProp: "rowId"
      }

      add: Transition {
        ParallelAnimation {
          NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Global.dur.normal; easing.type: Easing.OutCubic }
          NumberAnimation { property: "scale"; from: 0.94; to: 1; duration: Global.dur.normal; easing.type: Easing.OutCubic }
        }
      }
      remove: Transition {
        ParallelAnimation {
          NumberAnimation { property: "opacity"; to: 0; duration: Global.dur.fast }
          NumberAnimation { property: "scale"; to: 0.94; duration: Global.dur.fast }
        }
      }
      displaced: Transition {
        Anim { property: "y"; curve: Global.smooth }
      }

      delegate: Item {
        id: row
        required property var modelData

        width: ListView.view.width
        height: rowLoader.item ? rowLoader.item.implicitHeight : 0

        Loader {
          id: rowLoader
          width: parent.width
          sourceComponent: row.modelData.kind === "header" ? headerComp : tileComp
        }

        Component {
          id: headerComp
          NotificationGroupHeader {
            app: row.modelData.app
            count: panel.layoutData.counts[row.modelData.app] ?? 0
            expanded: panel.expandedApps[row.modelData.app] === true
            onToggled: panel.toggleApp(row.modelData.app)
            onCleared: NotificationService.removeApp(row.modelData.app)
          }
        }

        Component {
          id: tileComp
          NotificationHistoryTile {
            modelData: row.modelData.entry
            now: panel.now
            showApp: (panel.layoutData.counts[row.modelData.app] ?? 0) < 2
          }
        }
      }
    }

    // empty state
    ColumnLayout {
      anchors.centerIn: parent
      spacing: 8
      opacity: NotificationService.hasHistory ? 0 : 0.6
      visible: opacity > 0.01

      Behavior on opacity {
        NumberAnimation { duration: Global.dur.normal }
      }

      Icon {
        Layout.alignment: Qt.AlignHCenter
        text: NotificationService.doNotDisturb ? "notifications_off" : "notifications"
        font.pixelSize: 40
        color: Theme.m3on_surface_variant
      }

      Label {
        Layout.alignment: Qt.AlignHCenter
        text: "No notifications"
        font.pixelSize: 13
        textColor: Theme.m3on_surface_variant
      }
    }
  }
}
