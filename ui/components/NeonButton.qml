import QtQuick
import QtQuick.Controls
import Qt5Compat.GraphicalEffects
import "../styles"

Button {
    id: control
    property color mainColor: NeonStyle.cyanColor
    property bool primary: true
    property int fontSize: NeonStyle.fontBody
    property int btnHeight: 40
    property bool glow: true

    contentItem: Text {
        text: control.text || ""
        font.pixelSize: control.fontSize
        font.bold: true
        color: control.primary ? NeonStyle.textInverse : control.mainColor
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        
        Behavior on color { ColorAnimation { duration: NeonStyle.animFast } }
    }

    background: Rectangle {
        id: bg
        implicitWidth: 120
        implicitHeight: control.btnHeight
        radius: NeonStyle.radiusS
        color: control.primary ? control.mainColor : (control.pressed ? NeonStyle.surfacePressed : NeonStyle.surfaceElevated)
        border.color: control.primary ? "transparent" : (control.hovered ? control.mainColor : NeonStyle.borderColor)
        border.width: 1

        Behavior on color { ColorAnimation { duration: NeonStyle.animFast } }
        Behavior on border.color { ColorAnimation { duration: NeonStyle.animFast } }

        Rectangle {
            anchors.fill: parent
            color: "white"
            radius: parent.radius
            opacity: control.pressed ? 0.1 : (control.hovered ? 0.05 : 0)
            Behavior on opacity { NumberAnimation { duration: NeonStyle.animFast } }
        }
    }

    // Subtle glow for primary buttons
    Glow {
        anchors.fill: bg
        visible: control.glow && control.primary
        radius: 6
        samples: 12
        color: control.mainColor
        source: bg
        spread: 0.1
    }

    transform: Translate {
        y: control.pressed ? 1 : 0
        Behavior on y { NumberAnimation { duration: 50 } }
    }

    Keys.onSpacePressed: control.clicked()
    Keys.onReturnPressed: control.clicked()
}


