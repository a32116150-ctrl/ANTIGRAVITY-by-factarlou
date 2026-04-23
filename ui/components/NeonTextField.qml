import QtQuick
import QtQuick.Controls
import "../styles"

TextField {
    id: control
    
    property color accentColor: NeonStyle.cyanColor
    
    color: NeonStyle.textColor
    placeholderTextColor: NeonStyle.textMuted
    font.pixelSize: NeonStyle.fontBody
    selectionColor: accentColor
    selectedTextColor: NeonStyle.textInverse
    
    padding: 10
    leftPadding: 12
    rightPadding: 12
    topPadding: 10
    bottomPadding: 10

    background: Rectangle {
        implicitWidth: 200
        implicitHeight: 40
        color: control.activeFocus ? NeonStyle.surfaceElevated : NeonStyle.surfaceColor
        radius: NeonStyle.radiusS
        border.color: control.activeFocus ? control.accentColor : NeonStyle.borderColor
        border.width: 1
        
        Behavior on color { ColorAnimation { duration: NeonStyle.animFast } }
        Behavior on border.color { ColorAnimation { duration: NeonStyle.animFast } }
    }
}

