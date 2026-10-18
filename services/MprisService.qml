pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

import qs.common

Singleton {
  id: root

  // Only poll playback position when MediaPanel is actually open/visible
  property bool trackPosition: false

  onTrackPositionChanged: {
    if (trackPosition && activePlayer) {
      positionTick++
    }
  }

  function isIgnoredPlayer(p: MprisPlayer): bool {
    if (!p) return true
    const rawList = (Global.mprisIgnoredPlayers || "").split(",").map(s => s.trim().toLowerCase()).filter(s => s.length > 0)
    if (rawList.length === 0) return false
    const ident = (p.identity || "").toLowerCase()
    const dbusName = (p.dbusName || "").toLowerCase()
    for (let i = 0; i < rawList.length; i++) {
      const token = rawList[i]
      if (ident.includes(token) || dbusName.includes(token)) return true
    }
    return false
  }

  // prefer a currently-playing non-ignored player; fall back to the first available non-ignored one
  readonly property MprisPlayer activePlayer: {
    const valid = Mpris.players.values.filter(p => !root.isIgnoredPlayer(p))
    for (const p of valid) {
      if (p.playbackState === MprisPlaybackState.Playing) return p
    }
    return valid.length > 0 ? valid[0] : null
  }

  readonly property bool hasPlayer: activePlayer !== null
  readonly property bool playing: activePlayer?.playbackState === MprisPlaybackState.Playing

  readonly property string title: activePlayer?.trackTitle ?? ""
  readonly property string artist: activePlayer?.trackArtist ?? ""
  readonly property string artUrl: activePlayer?.trackArtUrl ?? ""

  readonly property bool canSeek: (activePlayer?.canSeek ?? false) && (activePlayer?.positionSupported ?? true)
  readonly property real length: (activePlayer && activePlayer.lengthSupported && activePlayer.length > 0) ? activePlayer.length : 0
  readonly property real position: (activePlayer && activePlayer.positionSupported && root.length > 0) ? activePlayer.position : 0

  function togglePlaying(): void { activePlayer?.togglePlaying() }
  function next(): void { activePlayer?.next() }
  function previous(): void { activePlayer?.previous() }
  function setPosition(seconds: real): void {
    if (activePlayer && root.canSeek) activePlayer.position = seconds
  }

  // position often doesn't update reactively per the docs — poll only while playing, visible, and supported
  Timer {
    interval: 1000
    running: root.playing && root.trackPosition && root.length > 0
    repeat: true
    onTriggered: {
      if (root.activePlayer) {
        root.positionTick++
      }
    }
  }
  property int positionTick: 0   // bump to force position-dependent bindings to re-evaluate
}
