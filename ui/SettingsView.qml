import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import "styles"
import "components"

Rectangle {
    id: root
    color: NeonStyle.backgroundColor

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: NeonStyle.spaceL
        spacing: NeonStyle.spaceL

        RowLayout {
            ColumnLayout {
                spacing: 2
                Text {
                    text: "SYSTEM SETTINGS"
                    color: NeonStyle.textColor
                    font.pixelSize: NeonStyle.fontHeader
                    font.bold: true
                }
                Text {
                    text: "Configure store preferences and hardware"
                    color: NeonStyle.textSecondaryColor
                    font.pixelSize: NeonStyle.fontBody
                }
            }
            Item { Layout.fillWidth: true }
            NeonButton {
                text: "SAVE ALL"
                mainColor: NeonStyle.greenColor
                btnHeight: 40
                onClicked: saveAll()
            }
        }

        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            ColumnLayout {
                width: parent.width - 24
                spacing: NeonStyle.spaceL

                NeonCard {
                    Layout.fillWidth: true
                    height: storeCol.implicitHeight + 40
                    
                    ColumnLayout {
                        id: storeCol
                        anchors.fill: parent
                        spacing: NeonStyle.spaceM
                        
                        Text { text: "STORE IDENTIFICATION"; color: NeonStyle.cyanColor; font.bold: true; font.pixelSize: NeonStyle.fontSubTitle }
                        
                        GridLayout {
                            columns: 2
                            columnSpacing: NeonStyle.spaceM
                            rowSpacing: NeonStyle.spaceM
                            Layout.fillWidth: true
                            
                            ColumnLayout {
                                Text { text: "Store Name"; color: NeonStyle.textSecondaryColor; font.pixelSize: 11 }
                                NeonTextField { id: store_name; text: posBackend ? (posBackend.settings.store_name || "") : ""; Layout.fillWidth: true }
                            }
                            ColumnLayout {
                                Text { text: "Tax ID"; color: NeonStyle.textSecondaryColor; font.pixelSize: 11 }
                                NeonTextField { id: store_tax_id; text: posBackend ? (posBackend.settings.store_tax_id || "") : ""; Layout.fillWidth: true }
                            }
                            ColumnLayout {
                                Text { text: "Phone"; color: NeonStyle.textSecondaryColor; font.pixelSize: 11 }
                                NeonTextField { id: store_phone; text: posBackend ? (posBackend.settings.store_phone || "") : ""; Layout.fillWidth: true }
                            }
                            ColumnLayout {
                                Text { text: "Address"; color: NeonStyle.textSecondaryColor; font.pixelSize: 11 }
                                NeonTextField { id: store_address; text: posBackend ? (posBackend.settings.store_address || "") : ""; Layout.fillWidth: true }
                            }
                        }
                    }
                }

                NeonCard {
                    Layout.fillWidth: true
                    height: fiscalCol.implicitHeight + 40
                    
                    ColumnLayout {
                        id: fiscalCol
                        anchors.fill: parent
                        spacing: NeonStyle.spaceM
                        
                        Text { text: "FISCAL & CURRENCY"; color: NeonStyle.magentaColor; font.bold: true; font.pixelSize: NeonStyle.fontSubTitle }
                        
                        RowLayout {
                            spacing: NeonStyle.spaceM
                            ColumnLayout {
                                Text { text: "VAT (%)"; color: NeonStyle.textSecondaryColor; font.pixelSize: 11 }
                                NeonTextField { id: tax_rate; text: posBackend ? (posBackend.settings.tax_rate || "19") : "19"; Layout.fillWidth: true }
                            }
                            ColumnLayout {
                                Text { text: "Currency"; color: NeonStyle.textSecondaryColor; font.pixelSize: 11 }
                                NeonTextField { id: currency; text: posBackend ? (posBackend.settings.currency || "TND") : "TND"; Layout.fillWidth: true }
                            }
                            ColumnLayout {
                                Text { text: "Stock Alert"; color: NeonStyle.textSecondaryColor; font.pixelSize: 11 }
                                NeonTextField { id: low_stock_threshold; text: posBackend ? (posBackend.settings.low_stock_threshold || "5") : "5"; Layout.fillWidth: true }
                            }
                        }
                    }
                }

                NeonCard {
                    Layout.fillWidth: true
                    height: actionCol.implicitHeight + 40
                    glowColor: NeonStyle.purpleGlow
                    
                    ColumnLayout {
                        id: actionCol
                        anchors.fill: parent
                        spacing: NeonStyle.spaceM
                        
                        Text { text: "SYSTEM ACTIONS"; color: NeonStyle.purpleColor; font.bold: true; font.pixelSize: NeonStyle.fontSubTitle }
                        
                        RowLayout {
                            spacing: NeonStyle.spaceM
                            NeonButton { text: "TEST PRINTER"; mainColor: NeonStyle.purpleColor; primary: false; Layout.fillWidth: true; btnHeight: 36 }
                            NeonButton { text: "SCANNER INFO"; mainColor: NeonStyle.purpleColor; primary: false; Layout.fillWidth: true; btnHeight: 36 }
                            NeonButton { text: "DB BACKUP"; mainColor: NeonStyle.purpleColor; primary: false; Layout.fillWidth: true; btnHeight: 36 }
                        }
                    }
                }

                Text {
                    id: statusMsg
                    text: ""
                    color: NeonStyle.successColor
                    font.pixelSize: NeonStyle.fontBody
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Item { height: 30 }
            }
        }
    }

    function saveAll() {
        if (!posBackend) return
        posBackend.saveSettings({
            "store_name": store_name.text,
            "store_tax_id": store_tax_id.text,
            "store_phone": store_phone.text,
            "store_address": store_address.text,
            "tax_rate": tax_rate.text,
            "currency": currency.text,
            "low_stock_threshold": low_stock_threshold.text
        })
        statusMsg.text = "Settings saved!"
        // Timer to clear status message
    }
}