import QtQuick

// Thin horizontal separator used between QuickMenu sections.
Rectangle {
    id: divider
    width: parent.width
    height: 1 * root.uiScale
    color: root.withAlpha(root.getColor("muted", "#a08d85"), 0.16)
}
