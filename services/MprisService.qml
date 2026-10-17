pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Mpris

Singleton {
  id: root

  // Only poll playback position when MediaPanel is actually open/visible
  property bool trackPosition: false

  onTrackPositionChanged: {
    if (trackPosition && activePlayer) {
      positionTick++
    }
  }

  // prefer a currently-playing player; fall back to the first available one
  readonly property MprisPlayer activePlayer: {
    for (const p of Mpris.players.values) {
      if (p.playbackState === MprisPlaybackState.Playing) return p
    }
    return Mpris.players.values.length > 0 ? Mpris.players.values[0] : null
  }

  readonly property bool hasPlayer: activePlayer !== null
  readonly property bool playing: activePlayer?.playbackState === MprisPlaybackState.Playing

  readonly property string title: activePlayer?.trackTitle ?? ""
  readonly property string artist: activePlayer?.trackArtist ?? ""
  readonly property string artUrl: activePlayer?.trackArtUrl ?? ""

  readonly property real position: activePlayer?.position ?? 0
  readonly property real length: activePlayer?.length ?? 0
  readonly property bool canSeek: activePlayer?.canSeek ?? false

  function togglePlaying(): void { activePlayer?.togglePlaying() }
  function next(): void { activePlayer?.next() }
  function previous(): void { activePlayer?.previous() }
  function setPosition(seconds: real): void {
    if (activePlayer && activePlayer.canSeek) activePlayer.position = seconds
  }

  // position often doesn't update reactively per the docs — poll only while playing AND visible
  Timer {
    interval: 1000
    running: root.playing && root.trackPosition
    repeat: true
    onTriggered: {
      if (root.activePlayer) {
        root.positionTick++
      }
    }
  }
  property int positionTick: 0   // bump to force position-dependent bindings to re-evaluate
}
