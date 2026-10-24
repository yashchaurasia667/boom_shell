pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

// Runs cava only while something wants the data (consumers bump `users`),
// so there's zero CPU cost when nothing is playing.
Singleton {
  id: root

  readonly property int barCount: 12
  property int users: 0                       // number of visible widgets that need data
  property var values: new Array(barCount).fill(0)   // 0..1 per bar

  readonly property string configPath: "/tmp/qs-cava.conf"

  Process {
    id: cava
    running: root.users > 0
    command: [
      "sh", "-c",
      "cat > " + root.configPath + " <<'CFG'\n"
      + "[general]\nbars = " + root.barCount + "\nframerate = 30\n"
      + "[input]\nmethod = pipewire\nsource = auto\n"
      + "[smoothing]\nnoise_reduction = 70\n"
      + "[output]\nmethod = raw\nraw_target = /dev/stdout\ndata_format = ascii\n"
      + "ascii_max_range = 100\nbar_delimiter = 59\nframe_delimiter = 10\n"
      + "CFG\n"
      + "exec cava -p " + root.configPath
    ]

    stdout: SplitParser {
      onRead: data => {
        const parts = data.split(";")
        const out = new Array(root.barCount)
        for (let i = 0; i < root.barCount; i++)
          out[i] = Math.min(1, (parseInt(parts[i]) || 0) / 100)
        root.values = out
      }
    }

    onRunningChanged: if (!running) root.values = new Array(root.barCount).fill(0)
  }
}
