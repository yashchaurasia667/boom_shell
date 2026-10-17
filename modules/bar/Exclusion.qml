import Quickshell
import Quickshell.Wayland

// Invisible 1x1 strip whose only job is reserving screen space on one edge.
PanelWindow {
  id: root

  required property string edge
  required property int size

  anchors {
    top: root.edge === "top"
    bottom: root.edge === "bottom"
    left: root.edge === "left"
    right: root.edge === "right"
  }
  implicitWidth: 1
  implicitHeight: 1
  exclusionMode: ExclusionMode.Normal
  exclusiveZone: size
  color: "transparent"
  mask: Region {}
  WlrLayershell.namespace: "notch-exclusion"
  WlrLayershell.layer: WlrLayer.Background
}
