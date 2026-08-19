import Quickshell
import QtQuick
import QtQuick.Shapes

// Full-screen NERV frame matching the mockup's <body> border: a red border ring
// around the whole screen. The interior is transparent so the wallpaper and
// anything behind show through (an opaque black fill would hide them). Backdrop
// layer, behind windows/bars, non-exclusive so clicks pass through.
//
// The ring's OUTER edge stays flush against the screen corners (square, so there
// are no gaps at the corners), while its INNER edge is rounded where it faces
// the desktop. Drawn as an even-odd filled shape: full-screen square minus a
// rounded rectangle inset by the ring thickness.
PanelWindow {
    id: frame
    visible: root.activeBar === "nerv"
    color: "transparent"
    aboveWindows: false
    exclusionMode: ExclusionMode.Ignore

    anchors { top: true; bottom: true; left: true; right: true }

    readonly property real thickness: 12 * root.uiScale
    readonly property real radius: 12 * root.uiScale

    Shape {
        anchors.fill: parent
        antialiasing: true

        ShapePath {
            fillRule: ShapePath.OddEvenFill
            fillColor: "#9D0A12"
            strokeColor: "transparent"

            // Outer boundary: the full screen, square at the corners.
            startX: 0
            startY: 0
            PathLine { x: frame.width; y: 0 }
            PathLine { x: frame.width; y: frame.height }
            PathLine { x: 0; y: frame.height }
            PathLine { x: 0; y: 0 }

            // Inner boundary: a rounded rectangle inset by the ring thickness.
            PathMove {
                x: frame.thickness
                y: frame.height - frame.thickness - frame.radius
            }
            PathLine { x: frame.thickness; y: frame.thickness + frame.radius }
            PathArc {
                x: frame.thickness + frame.radius; y: frame.thickness
                radiusX: frame.radius; radiusY: frame.radius
            }
            PathLine { x: frame.width - frame.thickness - frame.radius; y: frame.thickness }
            PathArc {
                x: frame.width - frame.thickness; y: frame.thickness + frame.radius
                radiusX: frame.radius; radiusY: frame.radius
            }
            PathLine { x: frame.width - frame.thickness; y: frame.height - frame.thickness - frame.radius }
            PathArc {
                x: frame.width - frame.thickness - frame.radius; y: frame.height - frame.thickness
                radiusX: frame.radius; radiusY: frame.radius
            }
            PathLine { x: frame.thickness + frame.radius; y: frame.height - frame.thickness }
            PathArc {
                x: frame.thickness; y: frame.height - frame.thickness - frame.radius
                radiusX: frame.radius; radiusY: frame.radius
            }
        }
    }
}
