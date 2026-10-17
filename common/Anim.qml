import QtQuick

NumberAnimation {
  property var curve: Global.spring
  duration: Global.dur.normal
  easing.type: Easing.BezierSpline
  easing.bezierCurve: curve
}
