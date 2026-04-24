import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import "components"
import "styles"

ApplicationWindow {
    id: window
    width: typeof screenWidth !== "undefined" ? screenWidth : 1280
    height: typeof screenHeight !== "undefined" ? screenHeight : 800
    minimumWidth: 1024
    minimumHeight: 700
    title: "ANTIGRAVITY POS - Modern Edition"
    color: NeonStyle.backgroundColor
    visible: true

    property string currentView: "dashboard"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // MINIMAL ICON SIDEBAR (Matches Screenshot)
        Rectangle {
            Layout.preferredWidth: 80
            Layout.fillHeight: true
            color: NeonStyle.surfaceColor
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NeonStyle.spaceM
                spacing: NeonStyle.spaceXL

                // LOGO
                Rectangle {
                    width: 48; height: 48; radius: 24
                    color: "transparent"
                    border.color: NeonStyle.primaryColor
                    border.width: 3
                    Layout.alignment: Qt.AlignHCenter
                    Text {
                        anchors.centerIn: parent
                        text: "A"
                        color: NeonStyle.primaryColor
                        font.pixelSize: 24
                        font.bold: true
                    }
                }

                // NAV ICONS
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: NeonStyle.spaceL
                    Layout.alignment: Qt.AlignHCenter

                    SidebarIcon { 
                        iconText: "🏠" 
                        active: currentView === "dashboard"
                        onClicked: { currentView = "dashboard"; loadView() }
                    }
                    SidebarIcon { 
                        iconText: "🛒" 
                        active: currentView === "sales"
                        onClicked: { currentView = "sales"; loadView() }
                    }
                    SidebarIcon { 
                        iconText: "📦" 
                        active: currentView === "inventory"
                        onClicked: { currentView = "inventory"; loadView() }
                    }
                    SidebarIcon { 
                        iconText: "📊" 
                        active: currentView === "reports"
                        onClicked: { currentView = "reports"; loadView() }
                    }
                }

                Item { Layout.fillHeight: true }

                // BOTTOM ICONS
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: NeonStyle.spaceL
                    Layout.alignment: Qt.AlignHCenter

                    SidebarIcon { 
                        iconText: "⚙️" 
                        active: currentView === "settings"
                        onClicked: { currentView = "settings"; loadView() }
                    }
                    SidebarIcon { 
                        iconText: "⏻" 
                        active: false
                        mainColor: NeonStyle.errorColor
                        onClicked: Qt.quit()
                    }
                }
            }
        }

        // MAIN CONTENT AREA
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // TOP BAR (Simplified)
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 80
                color: "transparent"
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: NeonStyle.spaceL
                    
                    ColumnLayout {
                        spacing: 2
                        Text {
                            text: "ANTIGRAVITY POS"
                            color: NeonStyle.textSecondaryColor
                            font.pixelSize: 12
                            font.bold: true
                            font.letterSpacing: 1
                        }
                        Text {
                            text: currentView === "sales" ? "Sales Terminal" : currentView.charAt(0).toUpperCase() + currentView.slice(1)
                            color: NeonStyle.textColor
                            font.pixelSize: 24
                            font.bold: true
                        }
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: NeonStyle.spaceM
                        
                        Text {
                            id: timeText
                            text: Qt.formatDateTime(new Date(), "HH:mm")
                            color: NeonStyle.textColor
                            font.pixelSize: 18
                            font.bold: true
                        }
                        
                        Timer {
                            interval: 10000; running: true; repeat: true
                            onTriggered: timeText.text = Qt.formatDateTime(new Date(), "HH:mm")
                        }

                        Rectangle {
                            width: 44; height: 44; radius: 22
                            color: NeonStyle.surfaceLightColor
                            Image {
                                anchors.centerIn: parent
                                width: 24; height: 24
                                source: "https://api.dicebear.com/7.x/avataaars/svg?seed=Felix"
                            }
                        }
                    }
                }
            }

            // LOADER
            Loader {
                id: viewLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }
        }
    }

    // INTERNAL COMPONENT FOR SIDEBAR ICONS
    component SidebarIcon : Control {
        id: iconControl
        property string iconText: ""
        property bool active: false
        property color mainColor: NeonStyle.primaryColor
        
        implicitWidth: 50
        implicitHeight: 50
        
        signal clicked()
        
        background: Rectangle {
            radius: 12
            color: iconControl.active ? NeonStyle.primaryGlow : "transparent"
            Behavior on color { ColorAnimation { duration: 200 } }
        }
        
        contentItem: Text {
            text: iconControl.iconText
            font.pixelSize: 24
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            color: iconControl.active ? iconControl.mainColor : NeonStyle.textMuted
            opacity: iconControl.active ? 1.0 : 0.6
            
            Behavior on color { ColorAnimation { duration: 200 } }
            Behavior on opacity { NumberAnimation { duration: 200 } }
        }
        
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onClicked: iconControl.clicked()
            cursorShape: Qt.PointingHandCursor
        }
    }

    function loadView() {
        viewLoader.opacity = 0
        Qt.callLater(function() {
            var viewUrl = "DashboardView.qml"
            if (currentView === "sales") viewUrl = "SalesView.qml"
            else if (currentView === "inventory") viewUrl = "InventoryView.qml"
            else if (currentView === "reports") viewUrl = "ReportsView.qml"
            else if (currentView === "settings") viewUrl = "SettingsView.qml"
            
            viewLoader.source = Qt.resolvedUrl(viewUrl)
            viewLoader.opacity = 1
        })
    }

    Component.onCompleted: {
        loadView()
    }
}