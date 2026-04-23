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
    title: "ANTIGRAVITY POS - Ultra Edition"
    color: NeonStyle.backgroundColor
    visible: true

    property string currentView: "dashboard"

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // SIDEBAR NAVIGATION
        Rectangle {
            Layout.preferredWidth: 240
            Layout.fillHeight: true
            color: NeonStyle.surfaceColor
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NeonStyle.spaceM
                spacing: NeonStyle.spaceL

                // LOGO
                ColumnLayout {
                    spacing: 0
                    Layout.alignment: Qt.AlignHCenter
                    Text {
                        text: "ANTIGRAVITY"
                        color: NeonStyle.cyanColor
                        font.pixelSize: 24
                        font.bold: true
                        font.letterSpacing: 2
                    }
                    Text {
                        text: "v3.0 ULTRA"
                        color: NeonStyle.textMuted
                        font.pixelSize: 10
                        font.bold: true
                        Layout.alignment: Qt.AlignRight
                    }
                }

                Item { Layout.preferredHeight: 20 }

                // NAV BUTTONS
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: NeonStyle.spaceS

                    NeonButton {
                        text: "DASHBOARD"
                        Layout.fillWidth: true
                        primary: currentView === "dashboard"
                        mainColor: NeonStyle.cyanColor
                        onClicked: { currentView = "dashboard"; loadView() }
                    }

                    NeonButton {
                        text: "SALES TERMINAL"
                        Layout.fillWidth: true
                        primary: currentView === "sales"
                        mainColor: NeonStyle.magentaColor
                        onClicked: { currentView = "sales"; loadView() }
                    }

                    NeonButton {
                        text: "INVENTORY"
                        Layout.fillWidth: true
                        primary: currentView === "inventory"
                        mainColor: NeonStyle.greenColor
                        onClicked: { currentView = "inventory"; loadView() }
                    }

                    NeonButton {
                        text: "REPORTS"
                        Layout.fillWidth: true
                        primary: currentView === "reports"
                        mainColor: NeonStyle.goldColor
                        onClicked: { currentView = "reports"; loadView() }
                    }

                    NeonButton {
                        text: "SETTINGS"
                        Layout.fillWidth: true
                        primary: currentView === "settings"
                        mainColor: NeonStyle.purpleColor
                        onClicked: { currentView = "settings"; loadView() }
                    }
                }

                Item { Layout.fillHeight: true }

                // FOOTER STATS
                NeonCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 100
                    glowColor: NeonStyle.cyanGlow
                    
                    ColumnLayout {
                        anchors.centerIn: parent
                        Text {
                            text: "SYSTEM STATUS"
                            color: NeonStyle.textMuted
                            font.pixelSize: 10
                            font.bold: true
                        }
                        RowLayout {
                            Rectangle { width: 8; height: 8; radius: 4; color: NeonStyle.successColor }
                            Text { text: "Database Online"; color: NeonStyle.textColor; font.pixelSize: 12 }
                        }
                        RowLayout {
                            Rectangle { width: 8; height: 8; radius: 4; color: NeonStyle.successColor }
                            Text { text: "Printer Ready"; color: NeonStyle.textColor; font.pixelSize: 12 }
                        }
                    }
                }
            }
        }

        // MAIN CONTENT AREA
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // TOP BAR
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 60
                color: NeonStyle.backgroundColor
                
                RowLayout {
                    anchors.fill: parent
                    anchors.margins: NeonStyle.spaceM
                    
                    Text {
                        text: currentView.toUpperCase()
                        color: NeonStyle.textSecondaryColor
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    RowLayout {
                        spacing: NeonStyle.spaceM
                        ColumnLayout {
                            spacing: 0
                            Text {
                                text: Qt.formatDateTime(new Date(), "dddd, dd MMMM")
                                color: NeonStyle.textMuted
                                font.pixelSize: 12
                                horizontalAlignment: Text.AlignRight
                            }
                            Text {
                                text: Qt.formatDateTime(new Date(), "HH:mm:ss")
                                color: NeonStyle.textColor
                                font.pixelSize: 16
                                font.bold: true
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                        
                        Rectangle {
                            width: 40; height: 40; radius: 20
                            color: NeonStyle.surfaceElevated
                            Text { anchors.centerIn: parent; text: "AC"; color: NeonStyle.cyanColor; font.bold: true }
                        }
                    }
                }
            }

            // LOADER
            Loader {
                id: viewLoader
                Layout.fillWidth: true
                Layout.fillHeight: true
                
                Behavior on opacity { NumberAnimation { duration: 250 } }
            }
        }
    }

    function loadView() {
        viewLoader.opacity = 0
        
        // Use a slight delay to ensure smooth transition
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