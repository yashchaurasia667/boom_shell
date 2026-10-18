pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Notifications

import qs.common

Singleton {
  id: root

  // Tracked notifications are ONLY the ones currently shown as popups.
  // Everything else lives in `history` (plain data snapshots).
  readonly property alias notifications: server.trackedNotifications
  readonly property int count: notifications.values.length
  readonly property bool hasNotifications: count > 0

  property bool doNotDisturb: Global.notifDoNotDisturb
  // let urgency=critical notifications through even while in Do Not Disturb
  readonly property bool allowCriticalInDnd: Global.notifAllowCriticalInDnd
  // how many notifications were silenced since DND was turned on
  property int missedCount: 0

  readonly property int defaultTimeout: Global.notifDefaultTimeout
  property int exitAnimDuration: Global.dur.normal

  // persistent history — independent of trackedNotifications, survives dismissal/expiry
  property var history: []
  readonly property int historyCount: history.length
  readonly property bool hasHistory: historyCount > 0
  readonly property int historyLimit: Global.notifHistoryLimit

  signal notified(notification: Notification)
  signal expiring(notification: Notification)

  Connections {
    target: Global
    function onNotifDoNotDisturbChanged(): void {
      if (root.doNotDisturb !== Global.notifDoNotDisturb) {
        root.doNotDisturb = Global.notifDoNotDisturb
      }
    }
  }

  function dismiss(notification: Notification): void {
    notification.dismiss()
  }

  function dismissAll(): void {
    for (const n of [...notifications.values]) n.dismiss()
  }

  function setDoNotDisturb(on: bool): void {
    root.doNotDisturb = on
  }

  function toggleDoNotDisturb(): void {
    root.doNotDisturb = !root.doNotDisturb
  }

  function clearHistory(): void {
    root.history = []
    root.missedCount = 0
  }

  function removeFromHistory(entryId: int): void {
    root.history = root.history.filter(e => e.id !== entryId)
  }

  function removeApp(appName: string): void {
    root.history = root.history.filter(e => (e.appName || "Other") !== appName)
  }

  property int _historyIdCounter: 0

  // Turning DND on takes down any popups that are currently visible and syncs with Global.
  onDoNotDisturbChanged: {
    if (Global.notifDoNotDisturb !== doNotDisturb) {
      Global.notifDoNotDisturb = doNotDisturb
    }
    if (doNotDisturb) {
      for (const n of [...notifications.values]) root._scheduleExpire(n, 0)
    } else {
      root.missedCount = 0
    }
  }

  onHistoryLimitChanged: {
    if (root.history.length > root.historyLimit) {
      root.history = root.history.slice(0, root.historyLimit)
    }
  }

  // play the toast's exit animation, then close the notification
  function _scheduleExpire(notification: Notification, delay: int): void {
    if (delay > 0) {
      expireTimer.createObject(root, { notification: notification, interval: delay })
    } else {
      _beginExit(notification)
    }
  }

  function _beginExit(notification: Notification): void {
    if (!notification || !root.notifications.values.includes(notification)) return
    root.expiring(notification)
    graceTimer.createObject(root, {
      notification: notification,
      interval: root.exitAnimDuration
    })
  }

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

      // snapshot plain data now — the Notification object may not survive closing
      const entry = {
        id: root._historyIdCounter++,
        summary: notification.summary,
        body: notification.body,
        image: notification.image,
        appIcon: notification.appIcon,
        appName: notification.appName,
        urgency: notification.urgency,
        timestamp: Date.now()
      }
      let h = [entry, ...root.history]
      if (h.length > root.historyLimit) h = h.slice(0, root.historyLimit)
      root.history = h

      // Do Not Disturb: keep it in the history, but never pop it up.
      const critical = notification.urgency === NotificationUrgency.Critical
      if (root.doNotDisturb && !(root.allowCriticalInDnd && critical)) {
        root.missedCount++
        notification.expire()   // not tracked/visible anymore; history keeps the record
        return
      }

      root.notified(notification)

      if (notification.expireTimeout !== 0) {
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
        root._beginExit(timer.notification)
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
