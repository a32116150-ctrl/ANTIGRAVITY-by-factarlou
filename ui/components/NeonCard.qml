import QtQuick
import Qt5Compat.GraphicalEffects
import "../styles"

Item {
    id: root
    
    property color shadowColor: "#10000000"
    property alias content: container.data
    property int padding: NeonStyle.spaceM
    property bool hasShadow: true
    
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

    DropShadow {
        anchors.fill: bg
        visible: root.hasShadow
        radius: 12
        samples: 24
        color: root.shadowColor
        source: bg
        verticalOffset: 4
    }
}
