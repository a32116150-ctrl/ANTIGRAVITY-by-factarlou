import QtQuick
import QtQuick.Controls
import "../styles"

TextField {
    id: control
    
    property color accentColor: NeonStyle.primaryColor
    
    color: NeonStyle.textColor
    placeholderTextColor: NeonStyle.textMuted
    font.pixelSize: NeonStyle.fontBody
    selectionColor: accentColor
    selectedTextColor: NeonStyle.textInverse
    
    verticalAlignment: TextInput.AlignVCenter
    
    padding: 12
    leftPadding: 16
    rightPadding: 16

    background: Rectangle {
        implicitWidth: 300
        implicitHeight: 44
        color: NeonStyle.surfaceLightColor
        radius: NeonStyle.radiusFull // Pill shaped
        border.color: control.activeFocus ? control.accentColor : NeonStyle.borderColor
        border.width: 1.5
        
        Behavior on color { ColorAnimation { duration: NeonStyle.animFast } }
        Behavior on border.color { ColorAnimation { duration: NeonStyle.animFast } }
    }
}
