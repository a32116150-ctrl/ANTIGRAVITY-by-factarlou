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

        // MAIN PRODUCT SECTION (LEFT)
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: NeonStyle.spaceL

            // TOP BAR: CATEGORY + SEARCH
            RowLayout {
                spacing: NeonStyle.spaceL
                
                ColumnLayout {
                    spacing: 0
                    Text {
                        text: "Items"
                        color: NeonStyle.primaryColor
                        font.pixelSize: NeonStyle.fontSubTitle
                        font.bold: true
                    }
                    RowLayout {
                        spacing: 8
                        Text {
                            text: (posBackend && posBackend.selectedCategory !== 0) ? 
                                  posBackend.categoriesList.find(c => c.id === posBackend.selectedCategory).name : "All Items"
                            color: NeonStyle.textColor
                            font.pixelSize: 28
                            font.bold: true
                        }
                        Text { text: "⌄"; color: NeonStyle.textColor; font.pixelSize: 20; font.bold: true }
                    }
                }

                Item { Layout.fillWidth: true }

                NeonTextField {
                    id: productSearch
                    placeholderText: "Search items..."
                    Layout.preferredWidth: 300
                    onTextChanged: if (posBackend) posBackend.searchProducts(text)
                }

                Rectangle {
                    width: 44; height: 44; radius: 12
                    color: NeonStyle.surfaceLightColor
                    border.color: NeonStyle.borderColor
                    Text { anchors.centerIn: parent; text: "⊶"; font.pixelSize: 20; color: NeonStyle.textColor }
                }
            }

            // CATEGORY PILLS
            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 48
                ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                
                RowLayout {
                    spacing: 12
                    NeonButton {
                        text: "All"
                        primary: posBackend ? posBackend.selectedCategory === 0 : true
                        pillRadius: NeonStyle.radiusFull
                        btnHeight: 40
                        onClicked: if (posBackend) posBackend.filterByCategory(0)
                    }
                    Repeater {
                        model: posBackend ? posBackend.categoriesModel : []
                        NeonButton {
                            text: modelData.name
                            primary: posBackend ? posBackend.selectedCategory === modelData.id : false
                            pillRadius: NeonStyle.radiusFull
                            btnHeight: 40
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
                cellWidth: 200
                cellHeight: 220
                model: posBackend ? posBackend.productsModel : []

                delegate: Item {
                    width: productGrid.cellWidth
                    height: productGrid.cellHeight
                    
                    NeonCard {
                        anchors.fill: parent
                        anchors.margins: 8
                        hasShadow: true
                        padding: 0
                        
                        ColumnLayout {
                            anchors.fill: parent
                            spacing: 0

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: NeonStyle.surfaceLightColor
                                radius: NeonStyle.radiusM
                                Rectangle { // Bottom corner radius fix
                                    anchors.bottom: parent.bottom
                                    width: parent.width; height: parent.radius
                                    color: parent.color
                                }
                                
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.name.substring(0, 2).toUpperCase()
                                    color: NeonStyle.primaryColor
                                    font.pixelSize: 40
                                    font.bold: true
                                    opacity: 0.3
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.margins: 12
                                spacing: 4

                                Text {
                                    text: modelData.name
                                    color: NeonStyle.textColor
                                    font.pixelSize: 16
                                    font.bold: true
                                    Layout.fillWidth: true
                                    elide: Text.ElideRight
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    Text {
                                        text: "TND " + Number(modelData.price).toFixed(3)
                                        color: NeonStyle.textColor
                                        font.bold: true
                                        font.pixelSize: 14
                                    }
                                    Item { Layout.fillWidth: true }
                                    
                                    // Add Button Circle
                                    Control {
                                        width: 32; height: 32
                                        background: Rectangle {
                                            radius: 16
                                            color: NeonStyle.accentColor
                                            Text { anchors.centerIn: parent; text: "+"; color: "white"; font.bold: true; font.pixelSize: 18 }
                                        }
                                        MouseArea {
                                            anchors.fill: parent
                                            onClicked: if (posBackend) posBackend.addToCart(modelData.id)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // ORDER SUMMARY PANEL (RIGHT)
        NeonCard {
            id: orderPanel
            Layout.preferredWidth: 380
            Layout.fillHeight: true
            padding: NeonStyle.spaceL
            hasShadow: true
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: parent.padding
                spacing: NeonStyle.spaceM

                Text {
                    text: "Current Order"
                    color: NeonStyle.textColor
                    font.pixelSize: 24
                    font.bold: true
                }

                // USER INFO
                RowLayout {
                    spacing: 12
                    Rectangle {
                        width: 36; height: 36; radius: 18; color: NeonStyle.surfaceLightColor
                        Image { anchors.centerIn: parent; width: 24; height: 24; source: "https://api.dicebear.com/7.x/avataaars/svg?seed=Emma" }
                    }
                    Text { text: "Cashier Terminal"; color: NeonStyle.textSecondaryColor; font.bold: true }
                }

                Item { Layout.preferredHeight: 10 }

                // CART LIST
                ListView {
                    id: cartView
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    model: posBackend ? posBackend.cart : []
                    spacing: 16
                    
                    delegate: RowLayout {
                        width: cartView.width
                        spacing: 12

                        Rectangle {
                            width: 50; height: 50; radius: 8; color: NeonStyle.surfaceLightColor
                            Text { anchors.centerIn: parent; text: modelData.name[0]; color: NeonStyle.primaryColor; font.bold: true }
                        }

                        ColumnLayout {
                            spacing: 2
                            Layout.fillWidth: true
                            Text { text: modelData.name; color: NeonStyle.textColor; font.bold: true; elide: Text.ElideRight }
                            Text { text: "TND " + Number(modelData.price).toFixed(3); color: NeonStyle.textSecondaryColor; font.bold: true }
                        }

                        RowLayout {
                            spacing: 8
                            // Minus Button
                            Rectangle {
                                width: 28; height: 28; radius: 14; border.color: NeonStyle.borderColor; color: "transparent"
                                Text { anchors.centerIn: parent; text: "−"; color: NeonStyle.textColor; font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: if (posBackend) posBackend.cartItemDecrement(index) }
                            }
                            Text { text: modelData.quantity; color: NeonStyle.textColor; font.bold: true; Layout.preferredWidth: 20; horizontalAlignment: Text.AlignHCenter }
                            // Plus Button
                            Rectangle {
                                width: 28; height: 28; radius: 14; color: NeonStyle.accentColor
                                Text { anchors.centerIn: parent; text: "+"; color: "white"; font.bold: true }
                                MouseArea { anchors.fill: parent; onClicked: if (posBackend) posBackend.cartItemIncrement(index) }
                            }
                        }
                    }
                }

                // BILLING DETAILS
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 12
                    
                    Rectangle { height: 1; Layout.fillWidth: true; color: NeonStyle.borderColor; opacity: 0.5 }
                    
                    RowLayout {
                        Text { text: "Subtotal"; color: NeonStyle.textMuted; font.pixelSize: 14 }
                        Item { Layout.fillWidth: true }
                        Text { text: "TND " + (posBackend ? posBackend.total.toFixed(3) : "0.000"); color: NeonStyle.textColor; font.bold: true }
                    }
                    RowLayout {
                        Text { text: "Service Charge"; color: NeonStyle.textMuted; font.pixelSize: 14 }
                        Item { Layout.fillWidth: true }
                        Text { text: "19%"; color: NeonStyle.textColor; font.bold: true }
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: NeonStyle.borderColor; Layout.topMargin: 8 }

                    RowLayout {
                        Layout.topMargin: 8
                        Text { text: "Total"; color: NeonStyle.textColor; font.pixelSize: 22; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text { 
                            text: (posBackend ? posBackend.total.toFixed(3) : "0.000") + " TND"
                            color: NeonStyle.textColor; font.pixelSize: 22; font.bold: true 
                        }
                    }
                }

                NeonButton {
                    text: "Continue"
                    Layout.fillWidth: true
                    btnHeight: 56
                    mainColor: NeonStyle.primaryColor
                    primary: true
                    pillRadius: 16
                    onClicked: if (posBackend) posBackend.checkout()
                }
            }
        }
    }
}