import QtQuick
import QtQuick.Shapes

// Reusable concave-eared notch shape that can be anchored to any edge:
// "top", "bottom", "left", or "right".
// Safely scales radii when width/height animate between 0 and target size.
Shape {
  id: root

  // Edge the flat base of the notch attaches to: "top" | "bottom" | "left" | "right"
  property string edge: "top"

  // Radii (can be customized via earRadius/cornerRadius or panelRadius/notchRadius)
  property real panelRadius: Global.panelRadius
  property real notchRadius: Global.notchRadius
  property real earRadius: panelRadius
  property real cornerRadius: notchRadius

  // Appearance
  property color color: Theme.m3surface
  property color strokeColor: "transparent"
  property real strokeWidth: -1

  preferredRendererType: Shape.CurveRenderer

  readonly property bool _isTop: root.edge === "top"
  readonly property bool _isBottom: root.edge === "bottom"
  readonly property bool _isLeft: root.edge === "left"
  readonly property bool _isRight: root.edge === "right"

  readonly property real _w: Math.max(0, root.width)
  readonly property real _h: Math.max(0, root.height)
  readonly property real _depth: (_isTop || _isBottom) ? _h : _w
  readonly property real _totalRadii: root.earRadius + root.cornerRadius
  readonly property real _depthScale: _totalRadii > 0 ? Math.min(1, _depth / _totalRadii) : 1

  readonly property real _er: root.earRadius * _depthScale
  readonly property real _cr: root.cornerRadius * _depthScale

  readonly property int _earDir: (_isTop || _isRight)
    ? PathArc.Clockwise
    : PathArc.Counterclockwise

  readonly property int _cornerDir: (_isTop || _isRight)
    ? PathArc.Counterclockwise
    : PathArc.Clockwise

  ShapePath {
    id: shapePath
    fillRule: ShapePath.OddEvenFill
    fillColor: root.color
    strokeColor: root.strokeColor
    strokeWidth: root.strokeWidth

    startX: root._isRight ? root._w : 0
    startY: root._isBottom ? root._h : 0

    // 1. First concave ear moving inward from the attached edge
    PathArc {
      x: root._isRight ? (root._w - root._er) : root._er
      y: root._isBottom ? (root._h - root._er) : root._er
      radiusX: root._er
      radiusY: root._er
      direction: root._earDir
    }

    // 2. First side line toward the opposite edge
    PathLine {
      x: root._isTop || root._isBottom
        ? root._er
        : (root._isLeft ? root._w - root._cr : root._cr)
      y: root._isLeft || root._isRight
        ? root._er
        : (root._isTop ? root._h - root._cr : root._cr)
    }

    // 3. First inner convex corner onto the opposite edge
    PathArc {
      x: root._isTop || root._isBottom
        ? (root._er + root._cr)
        : (root._isLeft ? root._w : 0)
      y: root._isLeft || root._isRight
        ? (root._er + root._cr)
        : (root._isTop ? root._h : 0)
      radiusX: root._cr
      radiusY: root._cr
      direction: root._cornerDir
    }

    // 4. Line along the opposite edge
    PathLine {
      x: root._isTop || root._isBottom
        ? (root._w - root._er - root._cr)
        : (root._isLeft ? root._w : 0)
      y: root._isLeft || root._isRight
        ? (root._h - root._er - root._cr)
        : (root._isTop ? root._h : 0)
    }

    // 5. Second inner convex corner turning back toward the attached edge
    PathArc {
      x: root._isTop || root._isBottom
        ? (root._w - root._er)
        : (root._isLeft ? root._w - root._cr : root._cr)
      y: root._isLeft || root._isRight
        ? (root._h - root._er)
        : (root._isTop ? root._h - root._cr : root._cr)
      radiusX: root._cr
      radiusY: root._cr
      direction: root._cornerDir
    }

    // 6. Second side line back toward the attached edge
    PathLine {
      x: root._isRight ? (root._w - root._er) : (root._isLeft ? root._er : (root._w - root._er))
      y: root._isBottom ? (root._h - root._er) : (root._isTop ? root._er : (root._h - root._er))
    }

    // 7. Second concave ear flaring out to the attached edge
    PathArc {
      x: root._isLeft ? 0 : root._w
      y: root._isTop ? 0 : root._h
      radiusX: root._er
      radiusY: root._er
      direction: root._earDir
    }
  }
}
