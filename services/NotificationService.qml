pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

import qs.common

Singleton {
  id: root

  readonly property alias notifications: server.trackedNotifications
  readonly property int count: notifications.values.length
  readonly property bool hasNotifications: count > 0

  property bool doNotDisturb: false
  property int defaultTimeout: 5000
  property int exitAnimDuration: Global.dur.normal

  // persistent history — independent of trackedNotifications, survives dismissal/expiry
  property var history: []
  readonly property int historyCount: history.length
  readonly property bool hasHistory: historyCount > 0
  property int historyLimit: 50

  signal notified(notification: Notification)
  signal expiring(notification: Notification)

  function dismiss(notification: Notification): void {
    notification.dismiss()
  }

  function dismissAll(): void {
    for (const n of [...notifications.values]) n.dismiss()
  }

  function clearHistory(): void {
    root.history = []
  }

  function removeFromHistory(entryId: int): void {
    root.history = root.history.filter(e => e.id !== entryId)
  }

  property int _historyIdCounter: 0

  NotificationServer {
    id: server

    bodySupported: true
    bodyMarkupSupported: true
    bodyHyperlinksSupported: true
    imageSupported: true
    actionsSupported: true
    actionIconsSupported: true
    persistenceSupported: true
    keepOnReload: false

    onNotification: (notification) => {
      notification.tracked = true
      root.notified(notification)

      // snapshot plain data now — the Notification object may not survive closing
      const entry = {
        id: root._historyIdCounter++,
        summary: notification.summary,
        body: notification.body,
        image: notification.image,
        appIcon: notification.appIcon,
        appName: notification.appName,
        timestamp: Date.now()
      }
      let h = [entry, ...root.history]
      if (h.length > root.historyLimit) h = h.slice(0, root.historyLimit)
      root.history = h

      if (!root.doNotDisturb && notification.expireTimeout !== 0) {
        const timeout = notification.expireTimeout > 0
          ? notification.expireTimeout
          : root.defaultTimeout

        expireTimer.createObject(root, {
          notification: notification,
          interval: timeout
        })
      }
    }
  }

  Component {
    id: expireTimer
    Timer {
      id: timer
      required property Notification notification
      running: true
      repeat: false
      onTriggered: {
        if (timer.notification && root.notifications.values.includes(timer.notification)) {
          root.expiring(timer.notification)
          graceTimer.createObject(root, {
            notification: timer.notification,
            interval: root.exitAnimDuration
          })
        }
        timer.destroy()
      }
    }
  }

  Component {
    id: graceTimer
    Timer {
      id: gtimer
      required property Notification notification
      running: true
      repeat: false
      onTriggered: {
        if (gtimer.notification && root.notifications.values.includes(gtimer.notification)) {
          gtimer.notification.expire()
        }
        gtimer.destroy()
      }
    }
  }
}
