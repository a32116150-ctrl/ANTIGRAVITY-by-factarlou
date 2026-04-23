import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import "styles"
import "components"

Rectangle {
    id: root
    color: NeonStyle.backgroundColor
    
    Component.onCompleted: {
        if (backend) backend.request_daily_summary()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: NeonStyle.spaceL
        spacing: NeonStyle.spaceL

        // HEADER
        ColumnLayout {
            spacing: 0
            Text {
                text: "DASHBOARD OVERVIEW"
                color: NeonStyle.textColor
                font.pixelSize: NeonStyle.fontHeader
                font.bold: true
            }
            Text {
                text: "Real-time business performance metrics"
                color: NeonStyle.textSecondaryColor
                font.pixelSize: NeonStyle.fontBody
            }
        }

        // STATS CARDS
        RowLayout {
            spacing: NeonStyle.spaceM
            Layout.fillWidth: true
            
            NeonCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                glowColor: NeonStyle.cyanGlow
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: NeonStyle.spaceXS
                    Text {
                        text: "DAILY REVENUE"
                        color: NeonStyle.textSecondaryColor
                        font.pixelSize: NeonStyle.fontCaption
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: (backend.dailySummary.revenue || 0).toFixed(3) + " TND"
                        color: NeonStyle.cyanColor
                        font.pixelSize: NeonStyle.fontHeader
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            NeonCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                glowColor: NeonStyle.magentaGlow
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: NeonStyle.spaceXS
                    Text {
                        text: "TRANSACTIONS"
                        color: NeonStyle.textSecondaryColor
                        font.pixelSize: NeonStyle.fontCaption
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: backend.dailySummary.count || 0
                        color: NeonStyle.magentaColor
                        font.pixelSize: NeonStyle.fontHeader
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            NeonCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                glowColor: NeonStyle.greenGlow
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: NeonStyle.spaceXS
                    Text {
                        text: "VAT COLLECTED"
                        color: NeonStyle.textSecondaryColor
                        font.pixelSize: NeonStyle.fontCaption
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: (backend.dailySummary.vat || 0).toFixed(3) + " TND"
                        color: NeonStyle.greenColor
                        font.pixelSize: NeonStyle.fontHeader
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        // LOW STOCK ALERT
        NeonCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            glowColor: NeonStyle.goldGlow
            
            ColumnLayout {
                anchors.fill: parent
                spacing: NeonStyle.spaceM
                
                RowLayout {
                    Text {
                        text: "LOW STOCK ALERTS"
                        color: NeonStyle.goldColor
                        font.pixelSize: NeonStyle.fontTitle
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: "Action Required"
                        color: NeonStyle.errorColor
                        font.pixelSize: NeonStyle.fontCaption
                        font.bold: true
                    }
                }
                
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: backend.productsModel.filter(p => p.stock <= 5)
                    spacing: NeonStyle.spaceS
                    
                    delegate: Rectangle {
                        width: parent.width
                        height: 40
                        color: NeonStyle.surfaceElevated
                        radius: NeonStyle.radiusS
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: NeonStyle.spaceM
                            Text {
                                text: modelData.name
                                color: NeonStyle.textColor
                                font.bold: true
                                Layout.fillWidth: true
                            }
                            Text {
                                text: "Only " + modelData.stock + " left"
                                color: NeonStyle.errorColor
                                font.bold: true
                            }
                        }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "All stock levels are healthy!"
                        color: NeonStyle.textMuted
                        visible: parent.count === 0
                    }
                }
            }
        }
    }
}
