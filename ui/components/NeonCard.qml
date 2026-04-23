import QtQuick
import Qt5Compat.GraphicalEffects
import "../styles"

Item {
    id: root
    
    property color glowColor: "transparent"
    property alias content: container.data
    property int padding: NeonStyle.spaceM
    
    Rectangle {
        id: bg
        anchors.fill: parent
        color: NeonStyle.surfaceColor
        radius: NeonStyle.radiusM
        border.color: NeonStyle.borderColor
        border.width: 1

        Item {
            id: container
            anchors.fill: parent
            anchors.margins: root.padding
        }
    }

    Glow {
        anchors.fill: bg
        visible: root.glowColor !== "transparent"
        radius: 10
        samples: 20
        color: root.glowColor
        source: bg
        spread: 0.1
    }
}
