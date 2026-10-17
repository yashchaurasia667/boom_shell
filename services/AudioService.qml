pragma Singleton

import Quickshell
import Quickshell.Services.Pipewire

Singleton {
  id: root

  readonly property PwNode sink: Pipewire.defaultAudioSink
  readonly property PwNode source: Pipewire.defaultAudioSource

  readonly property bool ready: sink?.ready ?? false
  readonly property bool muted: sink?.audio?.muted ?? false
  readonly property real volume: sink?.audio?.volume ?? 0

  readonly property bool sourceMuted: source?.audio?.muted ?? false
  readonly property real sourceVolume: source?.audio?.volume ?? 0

  function setVolume(vol: real): void {
    if (!sink?.ready || !sink?.audio) return
    sink.audio.volume = Math.max(0, Math.min(1, vol))
  }

  function setMuted(m: bool): void {
    if (!sink?.ready || !sink?.audio) return
    sink.audio.muted = m
  }

  function toggleMute(): void {
    setMuted(!muted)
  }

  function nudgeVolume(delta: real): void {
    setVolume(volume + delta)
  }

  function setSourceMuted(m: bool): void {
    if (!source?.ready || !source?.audio) return
    source.audio.muted = m
  }

  function toggleSourceMute(): void {
    setSourceMuted(!sourceMuted)
  }

  PwObjectTracker {
    objects: [root.sink, root.source]
  }
}
