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
        spacing: NeonStyle.spaceM

        // HEADER SECTION
        RowLayout {
            spacing: NeonStyle.spaceM
            ColumnLayout {
                spacing: 2
                Text { text: "STOCK MANAGEMENT"; color: NeonStyle.textColor; font.pixelSize: 24; font.bold: true }
                Text { text: "Monitor and manage your product inventory levels"; color: NeonStyle.textSecondaryColor; font.pixelSize: 14 }
            }
            Item { Layout.fillWidth: true }
            NeonTextField {
                id: searchInput
                placeholderText: "Search products..."
                Layout.preferredWidth: 250
                onTextChanged: if (posBackend) posBackend.searchProducts(text)
            }
            NeonButton {
                text: "ADD PRODUCT"
                mainColor: NeonStyle.greenColor
                btnHeight: 40
                onClicked: addDialog.open()
            }
        }

        // TABLE SECTION
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // FIXED HEADER
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 40
                color: NeonStyle.surfaceLightColor
                radius: NeonStyle.radiusS
                
                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: NeonStyle.spaceM + 12
                    anchors.rightMargin: NeonStyle.spaceM + 12
                    spacing: 20
                    
                    Text { text: "BARCODE"; color: NeonStyle.textMuted; font.bold: true; font.pixelSize: 12; Layout.preferredWidth: 120 }
                    Text { text: "PRODUCT NAME"; color: NeonStyle.textMuted; font.bold: true; font.pixelSize: 12; Layout.fillWidth: true }
                    Text { text: "STOCK"; color: NeonStyle.textMuted; font.bold: true; font.pixelSize: 12; Layout.preferredWidth: 80; horizontalAlignment: Text.AlignHCenter }
                    Text { text: "UNIT PRICE"; color: NeonStyle.textMuted; font.bold: true; font.pixelSize: 12; Layout.preferredWidth: 100; horizontalAlignment: Text.AlignRight }
                    Text { text: "ACTIONS"; color: NeonStyle.textMuted; font.bold: true; font.pixelSize: 12; Layout.preferredWidth: 100; horizontalAlignment: Text.AlignRight }
                }
            }

            Item { height: 10 }

            // SCROLLABLE LIST
            ListView {
                id: invList
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                spacing: 8
                model: posBackend ? posBackend.productsModel : []

                delegate: NeonCard {
                    width: invList.width
                    height: 56
                    padding: 0
                    hasShadow: false
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: NeonStyle.spaceM + 12
                        anchors.rightMargin: NeonStyle.spaceM + 12
                        spacing: 20

                        Text {
                            text: modelData.barcode || "---"
                            color: NeonStyle.textSecondaryColor
                            font.pixelSize: 14
                            Layout.preferredWidth: 120
                        }
                        
                        Text {
                            text: modelData.name
                            color: NeonStyle.textColor
                            font.pixelSize: 16
                            font.bold: true
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }
                        
                        Rectangle {
                            Layout.preferredWidth: 80
                            Layout.preferredHeight: 26
                            radius: 13
                            color: modelData.stock <= 5 ? NeonStyle.errorColor + "15" : NeonStyle.greenColor + "15"
                            Layout.alignment: Qt.AlignVCenter
                            
                            Text {
                                anchors.centerIn: parent
                                text: modelData.stock
                                color: modelData.stock <= 5 ? NeonStyle.errorColor : NeonStyle.greenColor
                                font.bold: true
                                font.pixelSize: 14
                            }
                        }

                        Text {
                            text: Number(modelData.price).toFixed(3)
                            color: NeonStyle.primaryColor
                            font.pixelSize: 16
                            font.bold: true
                            Layout.preferredWidth: 100
                            horizontalAlignment: Text.AlignRight
                        }
                        
                        RowLayout {
                            Layout.preferredWidth: 100
                            spacing: 10
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            
                            Button {
                                text: "✎"
                                width: 32; height: 32
                                flat: true
                                onClicked: {
                                    editId.text = modelData.id
                                    editName.text = modelData.name
                                    editBarcode.text = modelData.barcode
                                    editPrice.text = modelData.price
                                    editStock.text = modelData.stock
                                    editDialog.open()
                                }
                            }
                            
                            Button {
                                text: "🗑"
                                width: 32; height: 32
                                flat: true
                                onClicked: {
                                    if (posBackend) posBackend.deleteProduct(modelData.id)
                                }
                            }
                        }
                    }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: "No products found."
                    color: NeonStyle.textMuted
                    visible: invList.count === 0
                }
            }
        }
    }

    // DIALOGS
    Dialog {
        id: addDialog
        anchors.centerIn: parent
        width: 400
        modal: true
        background: NeonCard { hasShadow: true }
        header: Text { text: "NEW PRODUCT"; color: NeonStyle.textColor; font.bold: true; horizontalAlignment: Text.AlignHCenter; padding: 20 }
        
        ColumnLayout {
            anchors.fill: parent
            spacing: 15
            NeonTextField { id: nameField; placeholderText: "Name"; Layout.fillWidth: true }
            NeonTextField { id: barcodeField; placeholderText: "Barcode"; Layout.fillWidth: true }
            RowLayout {
                NeonTextField { id: priceField; placeholderText: "Price"; Layout.fillWidth: true }
                NeonTextField { id: stockField; placeholderText: "Stock"; Layout.fillWidth: true }
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                NeonButton { text: "CANCEL"; primary: false; onClicked: addDialog.close() }
                NeonButton { 
                    text: "ADD"; mainColor: NeonStyle.primaryColor
                    onClicked: {
                        if (posBackend) posBackend.addProduct(nameField.text, barcodeField.text, parseFloat(priceField.text), parseInt(stockField.text), 1)
                        addDialog.close()
                    }
                }
            }
        }
    }

    Dialog {
        id: editDialog
        anchors.centerIn: parent
        width: 400
        modal: true
        background: NeonCard { hasShadow: true }
        header: Text { text: "EDIT PRODUCT"; color: NeonStyle.textColor; font.bold: true; horizontalAlignment: Text.AlignHCenter; padding: 20 }
        Text { id: editId; visible: false }

        ColumnLayout {
            anchors.fill: parent
            spacing: 15
            NeonTextField { id: editName; Layout.fillWidth: true }
            NeonTextField { id: editBarcode; Layout.fillWidth: true }
            RowLayout {
                NeonTextField { id: editPrice; Layout.fillWidth: true }
                NeonTextField { id: editStock; Layout.fillWidth: true }
            }
            RowLayout {
                Layout.alignment: Qt.AlignRight
                NeonButton { text: "CANCEL"; primary: false; onClicked: editDialog.close() }
                NeonButton { 
                    text: "UPDATE"; mainColor: NeonStyle.primaryColor
                    onClicked: {
                        if (posBackend) posBackend.updateProduct(parseInt(editId.text), editName.text, editBarcode.text, parseFloat(editPrice.text), parseInt(editStock.text), 1)
                        editDialog.close()
                    }
                }
            }
        }
    }

    Component.onCompleted: {
        if (posBackend) posBackend.refreshInventory()
    }
}