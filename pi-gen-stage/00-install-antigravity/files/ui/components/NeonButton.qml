import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../styles"

Button {
    id: control
    property color mainColor: NeonStyle.primaryColor
    property bool primary: true
    property int fontSize: NeonStyle.fontBody
    property int btnHeight: 44
    property bool glow: false // Reduced for light theme
    property real pillRadius: NeonStyle.radiusL

    contentItem: Text {
        text: control.text || ""
        font.pixelSize: control.fontSize
        font.bold: true
        color: control.primary ? NeonStyle.textInverse : (control.hovered ? control.mainColor : NeonStyle.textSecondaryColor)
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        
        Behavior on color { ColorAnimation { duration: NeonStyle.animFast } }
    }

    background: Rectangle {
        id: bg
        implicitWidth: 120
        implicitHeight: control.btnHeight
        radius: control.pillRadius
        color: control.primary ? control.mainColor : (control.pressed ? NeonStyle.surfacePressed : "transparent")
        border.color: control.primary ? "transparent" : (control.hovered ? control.mainColor : NeonStyle.borderColor)
        border.width: 1.5

        Behavior on color { ColorAnimation { duration: NeonStyle.animFast } }
        Behavior on border.color { ColorAnimation { duration: NeonStyle.animFast } }

        // Subtle overlay for interaction
        Rectangle {
            anchors.fill: parent
            color: "black"
            radius: parent.radius
            opacity: control.pressed ? 0.05 : 0
            Behavior on opacity { NumberAnimation { duration: NeonStyle.animFast } }
        }
    }

    // Modern soft shadow instead of neon glow
    DropShadow {
        anchors.fill: bg
        visible: control.primary && !control.pressed
        radius: 8
        samples: 16
        color: "#20000000"
        source: bg
        verticalOffset: 2
    }

    transform: Scale {
        origin.x: control.width / 2
        origin.y: control.height / 2
        xScale: control.pressed ? 0.98 : 1.0
        yScale: control.pressed ? 0.98 : 1.0
        Behavior on xScale { NumberAnimation { duration: 50 } }
        Behavior on yScale { NumberAnimation { duration: 50 } }
    }

    Keys.onSpacePressed: control.clicked()
    Keys.onReturnPressed: control.clicked()
}
