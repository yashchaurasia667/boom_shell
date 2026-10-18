import QtQuick
import QtQuick.Layouts

import Quickshell
import Quickshell.Widgets
import Quickshell.Services.Notifications

import qs.common
import qs.components
import qs.services

Item {
  id: toastWrapper
  required property Notification modelData

  // true only when the collapse was triggered by a manual click (not auto-expire) —
  // gates whether exit animation finish should also tell the service to dismiss.
  property bool manualDismissPending: false
  property bool expanded: false
  readonly property int gap: 8   // space below the card lives inside the tile so the column needs no spacing
  readonly property real cardHeight: content.implicitHeight + 28
  readonly property real targetHeight: cardHeight + gap

  readonly property bool critical: modelData.urgency === NotificationUrgency.Critical
  readonly property bool hasImage: modelData.image !== ""
  readonly property string appIconPath: modelData.appIcon ? Quickshell.iconPath(modelData.appIcon, true) : ""
  // mirrors the service's timeout logic; 0 means the toast stays until dismissed
  readonly property int timeout: modelData.expireTimeout > 0
    ? modelData.expireTimeout
    : (modelData.expireTimeout === 0 ? 0 : NotificationService.defaultTimeout)

  readonly property color accent: critical ? Theme.m3error : Theme.m3primary

  Layout.fillWidth: true
  implicitHeight: expanded ? targetHeight : 0
  clip: true

  // start opening a beat after creation so the toast window is mapped and the animation is actually seen
  Timer {
    interval: 40
    running: true
    onTriggered: toastWrapper.expanded = true
  }

  Behavior on implicitHeight {
    // smooth in both directions: the spring overshoots, which pushes the stack around
    // on open and drives the height negative on close
    Anim {
      curve: Global.smooth
      onRunningChanged: {
        if (!running && !toastWrapper.expanded && toastWrapper.manualDismissPending) {
          NotificationService.dismiss(toastWrapper.modelData)
        }
      }
    }
  }

  function requestDismiss(): void {
    toastWrapper.manualDismissPending = true
    toastWrapper.expanded = false
  }

  // catches this notification's own auto-expire warning and animates it out,
  // without telling the service to close it again (the service does that itself)
  Connections {
    target: NotificationService
    function onExpiring(notification) {
      if (notification === toastWrapper.modelData) {
        toastWrapper.expanded = false
      }
    }
  }

  ClippingRectangle {
    id: toast
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    height: toastWrapper.cardHeight
    radius: 18
    color: hover.hovered ? Theme.m3surface_container_high : Theme.m3surface_container
    border.width: toastWrapper.critical ? 1 : 0
    border.color: Theme.m3error

    // content slides/fades in slightly after the height starts opening
    // slides in from / out to the screen edge (the wrapper clips it) while fading
    opacity: toastWrapper.expanded ? 1 : 0
    transform: Translate {
      x: toastWrapper.expanded ? 0 : toast.width * 0.6

      Behavior on x {
        NumberAnimation { duration: Global.dur.normal; easing.type: Easing.OutCubic }
      }
    }

    Behavior on color {
      ColorAnimation { duration: Global.dur.fast }
    }
    Behavior on opacity {
      NumberAnimation { duration: Global.dur.normal; easing.type: Easing.OutCubic }
    }

    HoverHandler {
      id: hover
    }

    TapHandler {
      acceptedButtons: Qt.RightButton | Qt.MiddleButton
      onTapped: toastWrapper.requestDismiss()
    }

    RowLayout {
      id: content
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.leftMargin: 14
      anchors.rightMargin: 12
      spacing: 12

      // image / app icon / fallback bell
      Item {
        Layout.preferredWidth: 44
        Layout.preferredHeight: 44
        Layout.alignment: Qt.AlignTop

        ClippingRectangle {
          anchors.fill: parent
          visible: toastWrapper.hasImage
          radius: 14
          color: Theme.m3surface_variant

          Image {
            anchors.fill: parent
            source: toastWrapper.hasImage ? toastWrapper.modelData.image : ""
            sourceSize: Qt.size(88, 88)
            asynchronous: true
            cache: false
            fillMode: Image.PreserveAspectCrop
          }
        }

        Rectangle {
          anchors.fill: parent
          visible: !toastWrapper.hasImage
          radius: 14
          color: toastWrapper.critical ? Theme.m3error_container : Theme.m3primary_container

          Image {
            anchors.centerIn: parent
            width: 26
            height: 26
            visible: toastWrapper.appIconPath !== ""
            source: toastWrapper.appIconPath
            sourceSize: Qt.size(52, 52)
            asynchronous: true
            fillMode: Image.PreserveAspectFit
          }

          Icon {
            anchors.centerIn: parent
            visible: toastWrapper.appIconPath === ""
            text: toastWrapper.critical ? "priority_high" : "notifications"
            font.pixelSize: 22
            color: toastWrapper.critical ? Theme.m3on_error_container : Theme.m3on_primary_container
          }
        }
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        RowLayout {
          Layout.fillWidth: true
          spacing: 6

          Label {
            Layout.fillWidth: true
            text: toastWrapper.modelData.appName !== "" ? toastWrapper.modelData.appName : "Notification"
            font.pixelSize: 11
            font.weight: 600
            textColor: toastWrapper.accent
          }

          Label {
            text: "now"
            font.pixelSize: 11
            textColor: Theme.m3on_surface_variant
          }

          // close button, only while hovered
          Rectangle {
            implicitWidth: 22
            implicitHeight: 22
            radius: 11
            color: closeMouse.containsMouse ? Theme.m3surface_container_highest : "transparent"
            opacity: hover.hovered ? 1 : 0

            Behavior on opacity {
              NumberAnimation { duration: Global.dur.fast }
            }
            Behavior on color {
              ColorAnimation { duration: Global.dur.fast }
            }

            Icon {
              anchors.centerIn: parent
              text: "close"
              font.pixelSize: 14
              color: Theme.m3on_surface_variant
            }

            MouseArea {
              id: closeMouse
              anchors.fill: parent
              hoverEnabled: true
              cursorShape: Qt.PointingHandCursor
              onClicked: toastWrapper.requestDismiss()
            }
          }
        }

        Label {
          Layout.fillWidth: true
          text: toastWrapper.modelData.summary
          font.pixelSize: 14
          font.weight: 600
          textColor: Theme.m3on_surface
          elide: Text.ElideRight
        }

        Label {
          Layout.fillWidth: true
          visible: toastWrapper.modelData.body !== ""
          text: toastWrapper.modelData.body
          font.pixelSize: 12
          textColor: Theme.m3on_surface_variant
          wrapMode: Text.WordWrap
          maximumLineCount: 3
          elide: Text.ElideRight
        }

        // actions as tonal pills
        Flow {
          Layout.fillWidth: true
          Layout.topMargin: 6
          visible: toastWrapper.modelData.actions.length > 0
          spacing: 6

          Repeater {
            model: toastWrapper.modelData.actions

            delegate: Rectangle {
              id: actionBtn
              required property NotificationAction modelData

              implicitWidth: actionLabel.implicitWidth + 24
              implicitHeight: 28
              radius: 14
              color: actionMouse.pressed ? Theme.m3primary
                : (actionMouse.containsMouse ? Theme.m3secondary_container : Theme.m3surface_container_highest)

              Behavior on color {
                ColorAnimation { duration: Global.dur.fast }
              }

              Label {
                id: actionLabel
                anchors.centerIn: parent
                text: actionBtn.modelData.text
                font.pixelSize: 12
                font.weight: 500
                textColor: actionMouse.pressed ? Theme.m3on_primary
                  : (actionMouse.containsMouse ? Theme.m3on_secondary_container : Theme.m3on_surface)
              }

              MouseArea {
                id: actionMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: actionBtn.modelData.invoke()
              }
            }
          }
        }
      }
    }

    // remaining-time bar along the bottom edge
    Rectangle {
      id: timeBar
      property real progress: 1

      visible: toastWrapper.timeout > 0
      anchors.bottom: parent.bottom
      anchors.left: parent.left
      height: 3
      width: parent.width * progress
      color: toastWrapper.accent
      opacity: 0.55

      NumberAnimation on progress {
        running: toastWrapper.expanded && toastWrapper.timeout > 0
        from: 1
        to: 0
        duration: Math.max(1, toastWrapper.timeout)
      }
    }
  }
}
