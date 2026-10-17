pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
  id: root

  property var entries: []   // list of {id, preview, isImage, thumbPath}
  property string filterText: ""

  readonly property string cacheDir: "/tmp/qs-cliphist-cache"

  function refresh() {
    listProc.running = true
  }

  function clear() {
    thumbQueue = []
    entries = []
    filterText = ""
  }

  function select(id) {
    copyProc.entryId = id
    copyProc.running = true
  }

  function remove(preview) {
    deleteProc.previewText = preview
    deleteProc.running = true
  }

  // call this from the delegate once it's visible, to lazily decode thumbnails
  function ensureThumbnail(id) {
    const idx = entries.findIndex(e => e.id === id)
    if (idx === -1) return
    if (entries[idx].thumbPath || !entries[idx].isImage) return
    if (thumbQueue.includes(id) || (thumbProc.running && thumbProc.entryId === id)) return

    thumbQueue.push(id)
    if (!thumbProc.running) processThumbQueue()
  }

  property var thumbQueue: []

  function processThumbQueue() {
    if (thumbQueue.length === 0) return
    const id = thumbQueue.shift()
    thumbProc.entryId = id
    thumbProc.running = true
  }

  Process {
    id: mkdirProc
    command: ["mkdir", "-p", root.cacheDir]
    running: true
  }

  Process {
    id: listProc
    command: ["cliphist", "list"]
    stdout: StdioCollector {
      onStreamFinished: {
        const lines = text.split("\n").filter(l => l.length > 0)
        const imageRe = /\[\[\s*binary data/i

        root.entries = lines.map(line => {
          const tabIdx = line.indexOf("\t")
          const id = line.substring(0, tabIdx)
          const preview = line.substring(tabIdx + 1)
          const isImage = imageRe.test(preview)
          return {
            id: id,
            preview: isImage ? "🖼  " + preview.replace(/[\[\]]/g, "").trim() : preview,
            isImage: isImage,
            thumbPath: ""
          }
        })
      }
    }
  }

  Process {
    id: thumbProc
    property string entryId: ""
    command: ["sh", "-c", `[ -s "${root.cacheDir}/${entryId}.img" ] || cliphist decode "${entryId}" > "${root.cacheDir}/${entryId}.img"`]
    onRunningChanged: {
      if (!running) {
        const idx = root.entries.findIndex(e => e.id === entryId)
        if (idx !== -1) {
          const updated = root.entries.slice()
          const old = updated[idx]
          updated[idx] = {
            id: old.id,
            preview: old.preview,
            isImage: old.isImage,
            thumbPath: root.cacheDir + "/" + entryId + ".img"
          }
          root.entries = updated
        }
        processThumbQueue()
      }
    }
  }

  Process {
    id: copyProc
    property string entryId: ""
    command: ["sh", "-c", `cliphist decode "${entryId}" | wl-copy`]
  }

  Process {
    id: deleteProc
    property string previewText: ""
    command: ["cliphist", "delete-query", previewText]
    onRunningChanged: if (!running) root.refresh()
  }
}
