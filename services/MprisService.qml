pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris

import qs.common

Singleton {
  id: root

  // Only poll playback position when MediaPanel is actually open/visible
  property bool trackPosition: false
  onTrackPositionChanged: if (trackPosition) refreshPosition()

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

  // ── player selection ──────────────────────────────────────────────
  // Browsers register hover previews (YouTube etc.) as extra MPRIS players. To avoid
  // latching onto them we: require a title, skip muted (volume 0) players that are
  // "playing", stay on the current player while it keeps playing, and make a new player
  // prove itself for ~0.8s before it can take over.

  property MprisPlayer activePlayer: null
  property var _pending: null
  property int _pendingTicks: 0

  function _isMutedPreview(p: MprisPlayer): bool {
    return (p.volumeSupported ?? false) && p.volume === 0
  }

  function recompute(): void {
    const valid = Mpris.players.values.filter(p => !isIgnoredPlayer(p) && (p.trackTitle ?? "") !== "")
    const playing = valid.filter(p => p.playbackState === MprisPlaybackState.Playing && !_isMutedPreview(p))
    const cur = activePlayer
    const curValid = cur !== null && valid.indexOf(cur) !== -1

    // current one is still playing → stay
    if (curValid && playing.indexOf(cur) !== -1) { _pending = null; _pendingTicks = 0; return }

    if (playing.length > 0) {
      const cand = playing[0]
      if (!curValid) { _switchTo(cand); return }          // nothing sensible selected → take it now
      if (_pending === cand) {
        if (++_pendingTicks >= 2) _switchTo(cand)         // ~0.8s of stable playback
      } else {
        _pending = cand
        _pendingTicks = 1
      }
      return
    }

    // nothing playing: keep the current (paused) player if it still exists, else first valid
    _pending = null; _pendingTicks = 0
    if (!curValid) _switchTo(valid.length > 0 ? valid[0] : null)
  }

  function _switchTo(p): void {
    _pending = null
    _pendingTicks = 0
    if (activePlayer !== p) activePlayer = p
  }

  Timer {
    interval: 400
    repeat: true
    running: true
    triggeredOnStart: true
    onTriggered: root.recompute()
  }

  Connections {
    target: Mpris.players
    function onValuesChanged() { root.recompute() }
  }

  onActivePlayerChanged: refreshPosition()

  readonly property bool hasPlayer: activePlayer !== null
  readonly property bool playing: activePlayer?.playbackState === MprisPlaybackState.Playing

  readonly property string title: activePlayer?.trackTitle ?? ""
  readonly property string artist: activePlayer?.trackArtist ?? ""

  // ── album art ─────────────────────────────────────────────────────
  // Raw URL as reported by the player (bare paths normalised to file://)
  readonly property string artUrl: {
    const raw = activePlayer?.trackArtUrl ?? ""
    return raw.startsWith("/") ? "file://" + raw : raw
  }

  // What the UI should actually load. Remote URLs are downloaded with curl first, since
  // Qt's Image frequently fails on https / redirects / odd hosts (ytimg, spotify, …).
  property string artSource: ""
  property int _artSeq: 0
  property string _artTarget: ""

  onArtUrlChanged: {
    artFetch.running = false
    if (artUrl === "") { artSource = ""; return }
    if (artUrl.startsWith("http://") || artUrl.startsWith("https://")) {
      artSource = ""                       // drop stale art from the previous track
      _artTarget = "/tmp/qs-mpris-art-" + (++_artSeq % 4) + "-" + Date.now() + ".img"
      artFetch.command = ["curl", "-fsSL", "--max-time", "10", "-o", _artTarget, artUrl]
      artFetch.running = true
    } else {
      artSource = artUrl
    }
  }

  Process {
    id: artFetch
    onExited: (code, status) => {
      if (code === 0) root.artSource = "file://" + root._artTarget
      else root.artSource = root.artUrl     // curl missing/failed → let Qt try directly
    }
  }

  // ── playback position / controls ──────────────────────────────────
  readonly property bool canSeek: (activePlayer?.canSeek ?? false) && (activePlayer?.positionSupported ?? true)
  readonly property real length: (activePlayer && activePlayer.lengthSupported && activePlayer.length > 0) ? activePlayer.length : 0

  // activePlayer.position isn't change-notified; depend on positionTick and emit
  // positionChanged() in refreshPosition() so it is actually re-read.
  readonly property real position: {
    positionTick
    return (activePlayer && activePlayer.positionSupported && root.length > 0) ? activePlayer.position : 0
  }

  function refreshPosition(): void {
    if (activePlayer && activePlayer.positionSupported) activePlayer.positionChanged()
    positionTick++
  }

  Connections {
    target: root.activePlayer
    ignoreUnknownSignals: true
    function onPlaybackStateChanged() { root.refreshPosition() }
    function onTrackTitleChanged() { root.refreshPosition() }
  }

  function togglePlaying(): void { activePlayer?.togglePlaying() }
  function next(): void { activePlayer?.next() }
  function previous(): void { activePlayer?.previous() }
  function setPosition(seconds: real): void {
    if (activePlayer && root.canSeek) {
      activePlayer.position = seconds
      refreshPosition()
    }
  }

  Timer {
    interval: 1000
    running: root.playing && root.trackPosition && root.length > 0
    repeat: true
    onTriggered: root.refreshPosition()
  }
  property int positionTick: 0
}
