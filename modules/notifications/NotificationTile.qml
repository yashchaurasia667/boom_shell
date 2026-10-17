import QtQuick
import QtQuick.Layouts

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
  readonly property real targetHeight: content.implicitHeight + 24

  Layout.fillWidth: true
  implicitHeight: expanded ? targetHeight : 0
  clip: true

  Component.onCompleted: Qt.callLater(() => { toastWrapper.expanded = true })

  Behavior on implicitHeight {
    Anim {
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

  Rectangle {
    id: toast
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: toastWrapper.targetHeight
    radius: 12
    color: Theme.m3surface
    border.color: Theme.m3surface_variant
    border.width: 1

    MouseArea {
      anchors.fill: parent
      acceptedButtons: Qt.LeftButton | Qt.RightButton
      onClicked: (mouse) => {
        if (mouse.button === Qt.RightButton) {
          toastWrapper.requestDismiss()
        }
      }
      onEntered: dismissBtn.visible = true
      onExited: dismissBtn.visible = false
      hoverEnabled: true
    }

    RowLayout {
      id: content
      anchors.left: parent.left
      anchors.right: parent.right
      anchors.verticalCenter: parent.verticalCenter
      anchors.margins: 12
      spacing: 10

      Image {
        visible: toastWrapper.modelData.image !== ""
        source: toastWrapper.modelData.image
        sourceSize: Qt.size(36, 36)
        asynchronous: true
        cache: false
        Layout.preferredWidth: 36
        Layout.preferredHeight: 36
        fillMode: Image.PreserveAspectCrop
      }

      Icon {
        visible: toastWrapper.modelData.image === "" && toastWrapper.modelData.appIcon !== ""
        text: "notifications"
        font.pixelSize: 20
        color: Theme.m3primary
      }

      ColumnLayout {
        Layout.fillWidth: true
        spacing: 2

        Label {
          Layout.fillWidth: true
          text: toastWrapper.modelData.summary
          font.bold: true
          font.pixelSize: 14
          elide: Text.ElideRight
        }

        Label {
          Layout.fillWidth: true
          visible: toastWrapper.modelData.body !== ""
          text: toastWrapper.modelData.body
          font.pixelSize: 12
          color: Theme.m3on_surface
          wrapMode: Text.WordWrap
          maximumLineCount: 3
          elide: Text.ElideRight
        }

        RowLayout {
          visible: toastWrapper.modelData.actions.length > 0
          spacing: 6
          Layout.topMargin: 4

          Repeater {
            model: toastWrapper.modelData.actions

            delegate: Rectangle {
              required property NotificationAction modelData

              implicitWidth: actionLabel.implicitWidth + 16
              implicitHeight: actionLabel.implicitHeight + 8
              radius: 6
              color: Theme.m3surface_variant

              Label {
                id: actionLabel
                anchors.centerIn: parent
                text: parent.modelData.text
                font.pixelSize: 12
              }

              MouseArea {
                anchors.fill: parent
                onClicked: parent.modelData.invoke()
              }
            }
          }
        }
      }

      Icon {
        id: dismissBtn
        visible: false
        text: "close"
        font.pixelSize: 14
        color: Theme.m3error

        MouseArea {
          anchors.fill: parent
          onClicked: toastWrapper.requestDismiss()
        }
      }
    }
  }
}
