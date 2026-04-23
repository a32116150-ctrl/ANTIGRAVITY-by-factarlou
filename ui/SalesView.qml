import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import "styles"
import "components"

Rectangle {
    id: root
    color: NeonStyle.backgroundColor

    RowLayout {
        anchors.fill: parent
        anchors.margins: NeonStyle.spaceL
        spacing: NeonStyle.spaceL

        // PRODUCT SECTION (LEFT)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: NeonStyle.spaceM

            // SEARCH & FILTERS
            RowLayout {
                spacing: NeonStyle.spaceM
                NeonTextField {
                    id: productSearch
                    placeholderText: "Search products..."
                    Layout.fillWidth: true
                    onTextChanged: if (posBackend) posBackend.searchProducts(text)
                }
                
                NeonButton {
                    text: "REFRESH"
                    mainColor: NeonStyle.cyanColor
                    btnHeight: 40
                    primary: false
                    onClicked: if (posBackend) posBackend.refreshInventory()
                }
            }

            // CATEGORIES
            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 45
                ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                
                RowLayout {
                    spacing: NeonStyle.spaceS
                    NeonButton {
                        text: "ALL"
                        primary: posBackend ? posBackend.selectedCategory === 0 : true
                        mainColor: NeonStyle.cyanColor
                        btnHeight: 32
                        fontSize: NeonStyle.fontCaption
                        onClicked: if (posBackend) posBackend.filterByCategory(0)
                    }
                    Repeater {
                        model: posBackend ? posBackend.categoriesModel : []
                        NeonButton {
                            text: modelData.name.toUpperCase()
                            primary: posBackend ? posBackend.selectedCategory === modelData.id : false
                            mainColor: NeonStyle.purpleColor
                            btnHeight: 32
                            fontSize: NeonStyle.fontCaption
                            onClicked: if (posBackend) posBackend.filterByCategory(modelData.id)
                        }
                    }
                }
            }

            // PRODUCT GRID
            GridView {
                id: productGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: 190
                cellHeight: 170
                model: posBackend ? posBackend.productsModel : []

                delegate: Item {
                    width: productGrid.cellWidth
                    height: productGrid.cellHeight
                    
                    NeonCard {
                        anchors.fill: parent
                        anchors.margins: 4
                        glowColor: modelData.stock <= 5 ? NeonStyle.errorColor + "15" : "transparent"
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 50
                                color: NeonStyle.surfaceLightColor
                                radius: NeonStyle.radiusM
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name[0].toUpperCase()
                                    color: NeonStyle.cyanColor
                                    font.pixelSize: 24
                                    font.bold: true
                                }
                            }

                            Text {
                                text: modelData.name
                                color: NeonStyle.textColor
                                font.pixelSize: NeonStyle.fontSubTitle
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                                horizontalAlignment: Text.AlignHCenter
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                Text {
                                    text: Number(modelData.price).toFixed(3)
                                    color: NeonStyle.greenColor
                                    font.bold: true
                                    font.pixelSize: NeonStyle.fontBody
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: "Stock: " + modelData.stock
                                    color: modelData.stock <= 5 ? NeonStyle.errorColor : NeonStyle.textMuted
                                    font.pixelSize: NeonStyle.fontTiny
                                }
                            }

                            NeonButton {
                                text: "ADD"
                                Layout.fillWidth: true
                                btnHeight: 32
                                mainColor: NeonStyle.cyanColor
                                fontSize: NeonStyle.fontCaption
                                onClicked: if (posBackend) posBackend.addToCart(modelData.id)
                            }
                        }
                    }
                }
                
                Text {
                    anchors.centerIn: parent
                    text: "No products available."
                    color: NeonStyle.textMuted
                    visible: productGrid.count === 0
                }
            }
        }

        // CART SECTION (RIGHT)
        NeonCard {
            Layout.preferredWidth: 360
            Layout.fillHeight: true
            glowColor: NeonStyle.magentaGlow
            
            ColumnLayout {
                anchors.fill: parent
                spacing: NeonStyle.spaceM

                Text {
                    text: "ORDER SUMMARY"
                    color: NeonStyle.textColor
                    font.pixelSize: NeonStyle.fontTitle
                    font.bold: true
                }

                // CART LIST
                ListView {
                    id: cartView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: posBackend ? posBackend.cart : []
                    spacing: 8
                    
                    delegate: Rectangle {
                        width: cartView.width
                        height: 60
                        color: NeonStyle.surfaceElevated
                        radius: NeonStyle.radiusS
                        
                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: NeonStyle.spaceM
                            spacing: 12

                            ColumnLayout {
                                spacing: 1
                                Layout.fillWidth: true
                                Text {
                                    text: modelData.name
                                    color: NeonStyle.textColor
                                    font.bold: true
                                    font.pixelSize: NeonStyle.fontBody
                                    elide: Text.ElideRight
                                }
                                Text {
                                    text: Number(modelData.price).toFixed(3) + " x " + modelData.quantity
                                    color: NeonStyle.textMuted
                                    font.pixelSize: NeonStyle.fontTiny
                                }
                            }

                            RowLayout {
                                spacing: 5
                                Button {
                                    text: "-"
                                    width: 28; height: 28
                                    onClicked: if (posBackend) posBackend.cartItemDecrement(index)
                                }
                                Text {
                                    text: modelData.quantity
                                    color: NeonStyle.cyanColor
                                    font.bold: true
                                    Layout.preferredWidth: 20
                                    horizontalAlignment: Text.AlignHCenter
                                }
                                Button {
                                    text: "+"
                                    width: 28; height: 28
                                    onClicked: if (posBackend) posBackend.cartItemIncrement(index)
                                }
                            }

                            Text {
                                text: (modelData.price * modelData.quantity).toFixed(3)
                                color: NeonStyle.greenColor
                                font.bold: true
                                Layout.preferredWidth: 65
                                horizontalAlignment: Text.AlignRight
                            }
                        }
                    }
                    
                    Text {
                        anchors.centerIn: parent
                        text: "Cart is empty"
                        color: NeonStyle.textMuted
                        visible: cartView.count === 0
                    }
                }

                // TOTALS
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 6
                    
                    Rectangle { height: 1; Layout.fillWidth: true; color: NeonStyle.borderColor }
                    
                    RowLayout {
                        Text { text: "SUBTOTAL"; color: NeonStyle.textMuted; font.pixelSize: NeonStyle.fontCaption }
                        Item { Layout.fillWidth: true }
                        Text { text: posBackend ? posBackend.total.toFixed(3) : "0.000"; color: NeonStyle.textColor; font.pixelSize: NeonStyle.fontBody }
                    }
                    
                    RowLayout {
                        Text { text: "TOTAL"; color: NeonStyle.textColor; font.pixelSize: NeonStyle.fontSubTitle; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { 
                            text: (posBackend ? posBackend.total.toFixed(3) : "0.000") + " TND"
                            color: NeonStyle.greenColor
                            font.pixelSize: 22
                            font.bold: true 
                        }
                    }
                }

                RowLayout {
                    spacing: NeonStyle.spaceM
                    NeonButton {
                        text: "CLEAR"
                        Layout.fillWidth: true
                        mainColor: NeonStyle.errorColor
                        primary: false
                        btnHeight: 44
                        onClicked: if (posBackend) posBackend.clearCart()
                    }
                    NeonButton {
                        text: "PAYMENT"
                        Layout.fillWidth: true
                        mainColor: NeonStyle.greenColor
                        primary: true
                        btnHeight: 44
                        onClicked: if (posBackend) posBackend.checkout()
                    }
                }
            }
        }
    }
}