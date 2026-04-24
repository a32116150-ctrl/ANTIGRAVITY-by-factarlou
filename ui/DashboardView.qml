import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import "styles"
import "components"

Rectangle {
    id: root
    color: NeonStyle.backgroundColor
    
    Component.onCompleted: {
        if (posBackend) posBackend.request_daily_summary()
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
                font.pixelSize: 28
                font.bold: true
            }
            Text {
                text: "Real-time business performance metrics"
                color: NeonStyle.textSecondaryColor
                font.pixelSize: 14
            }
        }

        // STATS CARDS
        RowLayout {
            spacing: NeonStyle.spaceM
            Layout.fillWidth: true
            
            NeonCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                hasShadow: true
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: "DAILY REVENUE"
                        color: NeonStyle.textSecondaryColor
                        font.pixelSize: 12
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: ((posBackend && posBackend.dailySummary) ? (posBackend.dailySummary.revenue || 0).toFixed(3) : "0.000") + " TND"
                        color: NeonStyle.primaryColor
                        font.pixelSize: 28
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            NeonCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                hasShadow: true
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: "TRANSACTIONS"
                        color: NeonStyle.textSecondaryColor
                        font.pixelSize: 12
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: (posBackend && posBackend.dailySummary) ? (posBackend.dailySummary.count || 0) : "0"
                        color: NeonStyle.accentColor
                        font.pixelSize: 28
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }

            NeonCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 120
                hasShadow: true
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 4
                    Text {
                        text: "VAT COLLECTED"
                        color: NeonStyle.textSecondaryColor
                        font.pixelSize: 12
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: ((posBackend && posBackend.dailySummary) ? (posBackend.dailySummary.vat || 0).toFixed(3) : "0.000") + " TND"
                        color: NeonStyle.greenColor
                        font.pixelSize: 28
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
            hasShadow: true
            padding: NeonStyle.spaceL
            
            ColumnLayout {
                anchors.fill: parent
                spacing: NeonStyle.spaceM
                
                RowLayout {
                    Text {
                        text: "LOW STOCK ALERTS"
                        color: NeonStyle.textColor
                        font.pixelSize: 20
                        font.bold: true
                    }
                    Item { Layout.fillWidth: true }
                    Rectangle {
                        width: 120; height: 30; radius: 15; color: NeonStyle.errorColor + "15"
                        Text { anchors.centerIn: parent; text: "Action Required"; color: NeonStyle.errorColor; font.bold: true; font.pixelSize: 12 }
                    }
                }
                
                ListView {
                    id: stockList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: (posBackend && posBackend.productsModel) ? posBackend.productsModel : []
                    spacing: 12
                    
                    delegate: Rectangle {
                        width: stockList.width
                        height: modelData.stock <= 5 ? 50 : 0
                        visible: modelData.stock <= 5
                        color: NeonStyle.surfaceLightColor
                        radius: 8
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 15
                            visible: parent.visible
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
                        visible: stockList.count === 0 || !posBackend.productsModel.some(p => p.stock <= 5)
                    }
                }
            }
        }
    }
}
