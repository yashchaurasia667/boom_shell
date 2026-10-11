pragma Singleton
import QtQuick

QtObject {
  // readonly property string font: "JetBrainsMono Nerd Font"
  readonly property string font: "Maven Pro"
  readonly property string iconFont: "Material Symbols Rounded"

  readonly property int fontSize: 14

  // ── sizing ──
  readonly property int pillHeight: 38
  readonly property int gap: 8
  readonly property int pad: 16
  readonly property int panelRadius: 28
  readonly property int border: 4            // screen border thickness
  readonly property int borderRadius: 18     // inner corner radius of the screen border
  readonly property int earRadius: 10        // concave corners where the notch meets the top border
  readonly property int notchRadius: 16      // notch bottom corner radius
  readonly property int reserveTop: pillHeight   // space tiled windows leave at the top (set to pillHeight so the notch never overlaps them)

}
