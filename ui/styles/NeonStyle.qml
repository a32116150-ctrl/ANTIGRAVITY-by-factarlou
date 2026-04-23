pragma Singleton
import QtQuick 6.0

QtObject {
    // Background colors - Deep professional dark theme
    readonly property string backgroundColor: "#0F111A"
    readonly property string surfaceColor: "#161925"
    readonly property string surfaceLightColor: "#1F2335"
    readonly property string surfaceElevated: "#24293E"
    readonly property string surfacePressed: "#2D334D"

    // Refined Neon accents (softer, more professional)
    readonly property string cyanColor: "#00E5FF"
    readonly property string cyanDarkColor: "#00B8CC"
    readonly property string cyanGlow: "#00E5FF22"
    
    readonly property string magentaColor: "#FF40B3"
    readonly property string magentaDarkColor: "#CC338F"
    readonly property string magentaGlow: "#FF40B322"
    
    readonly property string greenColor: "#00E676"
    readonly property string greenDarkColor: "#00B25B"
    readonly property string greenGlow: "#00E67622"
    
    readonly property string goldColor: "#FFC107"
    readonly property string goldDarkColor: "#CC9A06"
    readonly property string goldGlow: "#FFC10722"

    readonly property string purpleColor: "#7C4DFF"
    readonly property string purpleDarkColor: "#633DCC"
    readonly property string purpleGlow: "#7C4DFF22"

    // Functional colors
    readonly property string errorColor: "#FF5252"
    readonly property string successColor: "#00E676"
    readonly property string warningColor: "#FFD740"
    readonly property string infoColor: "#00E5FF"

    // Text colors - High contrast and readability
    readonly property string textColor: "#E2E8F0"
    readonly property string textSecondaryColor: "#94A3B8"
    readonly property string textMuted: "#64748B"
    readonly property string textInverse: "#0F111A"

    // Borders
    readonly property string borderColor: "#2A2F45"
    readonly property string borderLightColor: "#383F5C"

    // Font sizes
    readonly property int fontHeader: 26
    readonly property int fontTitle: 20
    readonly property int fontSubTitle: 16
    readonly property int fontBody: 14
    readonly property int fontCaption: 12
    readonly property int fontTiny: 10

    // Spacing
    readonly property int spaceXS: 4
    readonly property int spaceS: 8
    readonly property int spaceM: 16
    readonly property int spaceL: 24
    readonly property int spaceXL: 32

    // Radius
    readonly property real radiusS: 6
    readonly property real radiusM: 10
    readonly property real radiusL: 14
    readonly property real radiusFull: 99

    // Animation durations
    readonly property int animFast: 100
    readonly property int animNormal: 200
    readonly property int animSlow: 400

    // Gradients
    readonly property list<variant> cyanGradient: [
        { "position": 0.0, "color": "#00E5FF" },
        { "position": 1.0, "color": "#00B0FF" }
    ]
    
    readonly property list<variant> magentaGradient: [
        { "position": 0.0, "color": "#FF40B3" },
        { "position": 1.0, "color": "#7C4DFF" }
    ]

    readonly property list<variant> surfaceGradient: [
        { "position": 0.0, "color": "#1F2335" },
        { "position": 1.0, "color": "#161925" }
    ]
}