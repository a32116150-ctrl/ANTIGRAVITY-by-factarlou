pragma Singleton
import QtQuick 6.0

QtObject {
    // Background colors - Clean Modern Light Theme
    readonly property string backgroundColor: "#F8F9FB"
    readonly property string surfaceColor: "#FFFFFF"
    readonly property string surfaceLightColor: "#F1F5F9"
    readonly property string surfaceElevated: "#FFFFFF"
    readonly property string surfacePressed: "#E2E8F0"

    // Primary Accents (Modern Purple & Accent Dark)
    readonly property string primaryColor: "#5A2EE5"
    readonly property string primaryDarkColor: "#4321AB"
    readonly property string primaryGlow: "#5A2EE515"
    
    readonly property string accentColor: "#0F172A"
    readonly property string accentDarkColor: "#020617"
    readonly property string accentGlow: "#0F172A15"
    
    readonly property string cyanColor: "#0EA5E9"
    readonly property string magentaColor: "#D946EF"
    readonly property string greenColor: "#10B981"
    readonly property string goldColor: "#F59E0B"
    readonly property string purpleColor: "#8B5CF6"

    // Functional colors
    readonly property string errorColor: "#EF4444"
    readonly property string successColor: "#10B981"
    readonly property string warningColor: "#F59E0B"
    readonly property string infoColor: "#0EA5E9"

    // Text colors - High contrast for Light Theme
    readonly property string textColor: "#0F172A"
    readonly property string textSecondaryColor: "#475569"
    readonly property string textMuted: "#94A3B8"
    readonly property string textInverse: "#FFFFFF"

    // Borders
    readonly property string borderColor: "#E2E8F0"
    readonly property string borderLightColor: "#F1F5F9"

    // Font sizes
    readonly property int fontHeader: 28
    readonly property int fontTitle: 22
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

    // Radius (More rounded for Modern look)
    readonly property real radiusS: 8
    readonly property real radiusM: 12
    readonly property real radiusL: 20
    readonly property real radiusFull: 99

    // Animation durations
    readonly property int animFast: 100
    readonly property int animNormal: 250
    readonly property int animSlow: 450

    // Gradients
    readonly property list<variant> primaryGradient: [
        { "position": 0.0, "color": "#5A2EE5" },
        { "position": 1.0, "color": "#7C4DFF" }
    ]
}