import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

import qs.common
import qs.components

// Reusable expandable connection list panel used by both Wi-Fi and Bluetooth.
// Provides a header (back button, status icon, title/subtitle, scan toggle, power switch),
// an inline password/PIN prompt bar, and a scrollable item list.
Rectangle {
  id: panel

  // ── Header & State Properties ──
  property string title: "Connections"
  property string subtitle: ""
  property string headerIcon: "wifi"
  property string emptyIcon: "wifi_find"
  property string disabledIcon: "wifi_off"
  property string emptyText: "No items found"
  property string disabledText: "Turn on to view available items"
  property string scanIcon: "refresh"
  property string scanLabel: "Scan"
  property string scanningLabel: "Scanning..."

  property bool enabledState: false
  property bool scanning: false
  property bool connecting: false
  property string statusMessage: ""

  // ── List Model ──
  // Expects an array of JS objects normalized as:
  // {
  //   key: string,          // unique ID (e.g. SSID or MAC address)
  //   title: string,        // display name
  //   subtitle: string,     // status line (e.g. "Connected • 88%")
  //   icon: string,         // Material icon name
  //   connected: bool,      // currently connected
  //   known: bool,          // saved/paired
  //   locked: bool,         // shows lock icon and requires password
  //   rawItem: var          // underlying Network or BluetoothDevice object
  // }
  property var items: []

  // ── Prompt Configuration ──
  property string selectedKey: ""
  property var selectedItem: null
  property string promptIcon: "lock"
  property string promptPlaceholder: "Password..."
  property string connectButtonText: "Connect"
  property bool maskInput: true
  property bool showVisibilityToggle: true
  property string secretText: ""
  property bool showSecret: false

  readonly property bool promptOpen: enabledState && selectedKey !== "" && selectedItem !== null

  // ── Styling ──
  property color cardColor: Theme.m3surface_container_highest
  property color itemCardColor: Theme.m3surface_bright
  property color hoverCardColor: Theme.m3surface_variant

  property color activeColor: Theme.m3primary
  property color activeContentColor: Theme.m3surface

  property color trackColor: Theme.m3outline_variant
  property color textPrimary: Theme.m3on_surface
  property color textSecondary: Theme.m3on_surface_variant

  // ── Signals ──
  signal backClicked()
  signal powerToggled()
  signal scanToggled()
  signal itemClicked(var item)
  signal connectSubmitted(var item, string secret)
  signal disconnectRequested(var item)
  signal forgetRequested(var item)
  signal promptClosed()

  function closePrompt(): void {
    selectedKey = ""
    selectedItem = null
    secretText = ""
    showSecret = false
    statusMessage = ""
    promptClosed()
  }

  function openPromptFor(item): void {
    if (!item) return
    if (selectedKey === item.key) {
      closePrompt()
      return
    }
    selectedKey = item.key
    selectedItem = item
    secretText = ""
    showSecret = false
    statusMessage = ""
  }

  radius: 22
  color: panel.cardColor
  clip: true

  ColumnLayout {
    anchors.fill: parent
    anchors.margins: 18
    spacing: 12

    // ── 1. Header Bar ──
    RowLayout {
      Layout.fillWidth: true
      spacing: 12

      // Back Button
      Rectangle {
        Layout.preferredWidth: 38
        Layout.preferredHeight: 38
        radius: 19
        color: backMouse.containsMouse ? panel.hoverCardColor : panel.itemCardColor

        Icon {
          anchors.centerIn: parent
          text: "arrow_back"
          font.pixelSize: 20
          color: panel.textPrimary
        }

        MouseArea {
          id: backMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: {
            panel.closePrompt()
            panel.backClicked()
          }
        }
      }

      Icon {
        text: panel.enabledState ? panel.headerIcon : panel.disabledIcon
        font.pixelSize: 24
        color: panel.enabledState ? panel.textPrimary : panel.textSecondary
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 1

        Label {
          text: panel.title
          font.bold: true
          font.pixelSize: 17
          color: panel.textPrimary
        }

        Label {
          text: panel.subtitle
          font.pixelSize: 12
          color: panel.textSecondary
        }
      }

      // Scan / Refresh Pill Button
      Rectangle {
        visible: panel.enabledState
        Layout.preferredHeight: 34
        implicitWidth: scanBtnRow.implicitWidth + 24
        radius: 17
        color: panel.scanning
          ? panel.activeColor
          : (scanMouse.containsMouse ? panel.hoverCardColor : panel.itemCardColor)

        RowLayout {
          id: scanBtnRow
          anchors.centerIn: parent
          spacing: 6

          Icon {
            text: panel.scanIcon
            font.pixelSize: 16
            color: panel.scanning ? panel.activeContentColor : panel.textPrimary
          }

          Label {
            text: panel.scanning ? panel.scanningLabel : panel.scanLabel
            font.pixelSize: 12
            font.bold: true
            color: panel.scanning ? panel.activeContentColor : panel.textPrimary
          }
        }

        MouseArea {
          id: scanMouse
          anchors.fill: parent
          hoverEnabled: true
          cursorShape: Qt.PointingHandCursor
          onClicked: panel.scanToggled()
        }
      }

      // Power Toggle Switch
      Rectangle {
        implicitWidth: 48
        implicitHeight: 26
        radius: 13
        color: panel.enabledState ? panel.activeColor : panel.hoverCardColor

        Behavior on color {
          ColorAnimation { duration: Global.dur.fast }
        }

        Rectangle {
          width: 20
          height: 20
          radius: 10
          anchors.verticalCenter: parent.verticalCenter
          x: panel.enabledState ? parent.width - width - 3 : 3
          color: panel.enabledState ? panel.activeContentColor : panel.textPrimary

          Behavior on x {
            Anim {}
          }
        }

        MouseArea {
          anchors.fill: parent
          cursorShape: Qt.PointingHandCursor
          onClicked: panel.powerToggled()
        }
      }
    }

    // Divider
    Rectangle {
      Layout.fillWidth: true
      height: 1
      color: panel.trackColor
      opacity: 0.5
    }

    // ── 2. Persistent Inline Password / PIN Prompt Card ──
    Rectangle {
      id: promptCard
      visible: panel.promptOpen
      Layout.fillWidth: true
      implicitHeight: promptCol.implicitHeight + 24
      radius: 16
      color: panel.itemCardColor
      border.width: 1
      border.color: panel.activeColor

      onVisibleChanged: {
        if (visible && !(panel.selectedItem?.connected ?? false)) {
          Qt.callLater(() => secretInput.forceActiveFocus())
        }
      }

      ColumnLayout {
        id: promptCol
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        anchors.margins: 14
        spacing: 10

        RowLayout {
          Layout.fillWidth: true
          spacing: 10

          Icon {
            text: panel.selectedItem?.icon || panel.promptIcon
            font.pixelSize: 20
            color: panel.activeColor
          }

          ColumnLayout {
            Layout.fillWidth: true
            spacing: 1

            Label {
              Layout.fillWidth: true
              text: panel.selectedItem?.title || panel.selectedKey
              font.bold: true
              font.pixelSize: 14
              color: panel.textPrimary
              elide: Text.ElideRight
            }

            Label {
              text: panel.statusMessage !== ""
                ? panel.statusMessage
                : ((panel.selectedItem?.connected ?? false)
                    ? "Connected"
                    : (panel.selectedItem?.subtitle || ""))
              font.pixelSize: 11
              color: panel.textSecondary
            }
          }

          // Forget button for saved / paired items
          Rectangle {
            visible: (panel.selectedItem?.known ?? false) || (panel.selectedItem?.connected ?? false)
            implicitWidth: forgetLbl.implicitWidth + 20
            Layout.preferredHeight: 30
            radius: 15
            color: panel.cardColor

            Label {
              id: forgetLbl
              anchors.centerIn: parent
              text: "Forget"
              font.pixelSize: 12
              color: Theme.m3error
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                const target = panel.selectedItem
                panel.closePrompt()
                if (target) panel.forgetRequested(target)
              }
            }
          }

          // Close Prompt Button
          Rectangle {
            Layout.preferredWidth: 28
            Layout.preferredHeight: 28
            radius: 14
            color: panel.cardColor

            Icon {
              anchors.centerIn: parent
              text: "close"
              font.pixelSize: 16
              color: panel.textSecondary
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: panel.closePrompt()
            }
          }
        }

        // Password / PIN Input Row (when not connected)
        RowLayout {
          visible: !(panel.selectedItem?.connected ?? false)
          Layout.fillWidth: true
          spacing: 8

          Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            radius: 12
            color: panel.cardColor
            border.width: secretInput.activeFocus ? 1 : 0
            border.color: panel.activeColor

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 12
              anchors.rightMargin: 10
              spacing: 8

              Icon {
                text: panel.promptIcon
                font.pixelSize: 16
                color: panel.textSecondary
              }

              TextInput {
                id: secretInput
                Layout.fillWidth: true
                font.family: Global.font
                font.pixelSize: 13
                color: panel.textPrimary
                echoMode: (panel.maskInput && !panel.showSecret) ? TextInput.Password : TextInput.Normal
                clip: true
                text: panel.secretText
                onTextChanged: panel.secretText = text

                Keys.onReturnPressed: panel.connectSubmitted(panel.selectedItem, panel.secretText)
                Keys.onEnterPressed: panel.connectSubmitted(panel.selectedItem, panel.secretText)
                Keys.onEscapePressed: panel.closePrompt()

                Label {
                  visible: secretInput.text === ""
                  text: panel.promptPlaceholder
                  font.pixelSize: 12
                  color: panel.textSecondary
                  opacity: 0.6
                  anchors.verticalCenter: parent.verticalCenter
                }
              }

              Icon {
                visible: panel.showVisibilityToggle && panel.maskInput
                text: panel.showSecret ? "visibility_off" : "visibility"
                font.pixelSize: 17
                color: panel.textSecondary

                MouseArea {
                  anchors.fill: parent
                  cursorShape: Qt.PointingHandCursor
                  onClicked: panel.showSecret = !panel.showSecret
                }
              }
            }
          }

          Rectangle {
            Layout.preferredHeight: 38
            implicitWidth: connectBtnLbl.implicitWidth + 28
            radius: 12
            color: panel.activeColor

            Label {
              id: connectBtnLbl
              anchors.centerIn: parent
              text: panel.connecting ? "Connecting..." : panel.connectButtonText
              font.bold: true
              font.pixelSize: 13
              color: panel.activeContentColor
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: panel.connectSubmitted(panel.selectedItem, panel.secretText)
            }
          }
        }

        // Disconnect Row (when clicking an already connected item)
        RowLayout {
          visible: panel.selectedItem?.connected ?? false
          Layout.fillWidth: true

          Item { Layout.fillWidth: true }

          Rectangle {
            Layout.preferredHeight: 34
            implicitWidth: discBtnLbl.implicitWidth + 28
            radius: 12
            color: panel.activeColor

            Label {
              id: discBtnLbl
              anchors.centerIn: parent
              text: "Disconnect"
              font.bold: true
              font.pixelSize: 13
              color: panel.activeContentColor
            }

            MouseArea {
              anchors.fill: parent
              cursorShape: Qt.PointingHandCursor
              onClicked: {
                const target = panel.selectedItem
                panel.closePrompt()
                if (target) panel.disconnectRequested(target)
              }
            }
          }
        }
      }
    }

    // ── 3. Scrollable List of Available Items ──
    ScrollView {
      Layout.fillWidth: true
      Layout.fillHeight: true
      clip: true

      ColumnLayout {
        width: parent.width
        spacing: 8

        Repeater {
          model: panel.enabledState ? panel.items : []

          delegate: Rectangle {
            id: rowTile
            required property var modelData
            readonly property bool isSelected: panel.selectedKey === modelData.key

            Layout.fillWidth: true
            implicitHeight: 54
            radius: 14
            color: modelData.connected
              ? panel.activeColor
              : (isSelected || rowMouse.containsMouse ? panel.hoverCardColor : panel.itemCardColor)

            Behavior on color {
              ColorAnimation { duration: Global.dur.fast }
            }

            RowLayout {
              anchors.fill: parent
              anchors.leftMargin: 14
              anchors.rightMargin: 14
              spacing: 12

              Icon {
                text: rowTile.modelData.icon
                font.pixelSize: 21
                color: rowTile.modelData.connected ? panel.activeContentColor : panel.textPrimary
              }

              ColumnLayout {
                Layout.fillWidth: true
                spacing: 1

                Label {
                  Layout.fillWidth: true
                  text: rowTile.modelData.title
                  font.bold: true
                  font.pixelSize: 14
                  color: rowTile.modelData.connected ? panel.activeContentColor : panel.textPrimary
                  elide: Text.ElideRight
                }

                Label {
                  Layout.fillWidth: true
                  text: rowTile.modelData.subtitle
                  font.pixelSize: 11
                  color: rowTile.modelData.connected
                    ? Qt.rgba(panel.activeContentColor.r, panel.activeContentColor.g, panel.activeContentColor.b, 0.75)
                    : panel.textSecondary
                  elide: Text.ElideRight
                }
              }

              Icon {
                visible: rowTile.modelData.locked ?? false
                text: "lock"
                font.pixelSize: 16
                color: rowTile.modelData.connected
                  ? Qt.rgba(panel.activeContentColor.r, panel.activeContentColor.g, panel.activeContentColor.b, 0.75)
                  : panel.textSecondary
              }

              Icon {
                text: rowTile.modelData.connected ? "check_circle" : "chevron_right"
                font.pixelSize: 18
                color: rowTile.modelData.connected ? panel.activeContentColor : panel.textSecondary
              }
            }

            MouseArea {
              id: rowMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: panel.itemClicked(rowTile.modelData)
            }
          }
        }

        // Empty / Disabled State Placeholder
        ColumnLayout {
          visible: !panel.enabledState || panel.items.length === 0
          Layout.fillWidth: true
          Layout.topMargin: 56
          spacing: 8

          Icon {
            Layout.alignment: Qt.AlignHCenter
            text: panel.enabledState ? panel.emptyIcon : panel.disabledIcon
            font.pixelSize: 38
            color: panel.textSecondary
          }

          Label {
            Layout.alignment: Qt.AlignHCenter
            text: !panel.enabledState ? panel.disabledText : panel.emptyText
            font.pixelSize: 14
            color: panel.textSecondary
          }
        }
      }
    }
  }
}
