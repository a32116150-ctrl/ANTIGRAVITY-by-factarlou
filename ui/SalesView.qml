import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import "styles"
import "components"

Rectangle {
    id: root
    color: NeonStyle.backgroundColor

    // Palette for product avatar backgrounds (cycles by index)
    readonly property var avatarColors: [
        "#EDE9FE", "#FCE7F3", "#D1FAE5", "#FEF3C7",
        "#DBEAFE", "#FFE4E6", "#F0FDF4", "#FFF7ED"
    ]
    readonly property var avatarTextColors: [
        "#7C3AED", "#DB2777", "#059669", "#D97706",
        "#2563EB", "#E11D48", "#16A34A", "#EA580C"
    ]

    RowLayout {
        anchors.fill: parent
        anchors.margins: NeonStyle.spaceL
        spacing: NeonStyle.spaceL

        // ═══════════════════════════════════════════════════════════════════════
        // LEFT PANEL — Product browser
        // ═══════════════════════════════════════════════════════════════════════
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: NeonStyle.spaceM

            // ── TOP BAR ───────────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: NeonStyle.spaceM

                ColumnLayout {
                    spacing: 2
                    Text {
                        text: "Items"
                        color: NeonStyle.primaryColor
                        font.pixelSize: 13
                        font.bold: true
                        font.letterSpacing: 0.5
                    }
                    Text {
                        // NOTE: If categoriesList is a QAbstractListModel, .find() won't work.
                        // Expose it as a plain JS array from Python for this to function.
                        text: (posBackend && posBackend.selectedCategory !== 0 && posBackend.categoriesList)
                              ? (posBackend.categoriesList.find(function(c) { return c.id === posBackend.selectedCategory }) || { name: "All Items" }).name
                              : "All Items"
                        color: NeonStyle.textColor
                        font.pixelSize: 26
                        font.bold: true
                    }
                }

                Item { Layout.fillWidth: true }

                // Search field
                Rectangle {
                    Layout.preferredWidth: 280
                    height: 44
                    radius: NeonStyle.radiusM
                    color: NeonStyle.surfaceColor
                    border.color: searchFocus.activeFocus ? NeonStyle.primaryColor : NeonStyle.borderColor
                    border.width: searchFocus.activeFocus ? 2 : 1

                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    RowLayout {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 8

                        Text { text: "🔍"; font.pixelSize: 14; opacity: 0.5 }

                        TextInput {
                            id: searchFocus
                            Layout.fillWidth: true
                            font.pixelSize: 14
                            color: NeonStyle.textColor
                            // Placeholder
                            onTextChanged: if (posBackend) posBackend.searchProducts(text)

                            Text {
                                anchors.fill: parent
                                text: "Search items..."
                                color: NeonStyle.textMuted
                                font.pixelSize: 14
                                visible: parent.text === ""
                                verticalAlignment: Text.AlignVCenter
                            }
                        }

                        // Clear button
                        Rectangle {
                            width: 18; height: 18; radius: 9
                            color: NeonStyle.textMuted
                            visible: searchFocus.text !== ""
                            Text { anchors.centerIn: parent; text: "✕"; color: "white"; font.pixelSize: 10; font.bold: true }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: searchFocus.text = "" }
                        }
                    }
                }
            }

            // ── CATEGORY PILLS ────────────────────────────────────────────────
            ScrollView {
                Layout.fillWidth: true
                Layout.preferredHeight: 44
                contentWidth: pillRow.implicitWidth
                ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff

                RowLayout {
                    id: pillRow
                    spacing: 8
                    height: 44

                    // "All" pill
                    Rectangle {
                        width: allPillText.implicitWidth + 28
                        height: 36
                        radius: NeonStyle.radiusFull
                        color: (!posBackend || posBackend.selectedCategory === 0) ? NeonStyle.primaryColor : NeonStyle.surfaceColor
                        border.color: (!posBackend || posBackend.selectedCategory === 0) ? "transparent" : NeonStyle.borderColor

                        Text {
                            id: allPillText
                            anchors.centerIn: parent
                            text: "All"
                            color: (!posBackend || posBackend.selectedCategory === 0) ? "white" : NeonStyle.textColor
                            font.bold: true
                            font.pixelSize: 14
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: if (posBackend) posBackend.filterByCategory(0)
                        }
                    }

                    Repeater {
                        model: posBackend ? posBackend.categoriesModel : []

                        Rectangle {
                            required property var modelData
                            width: pillCatText.implicitWidth + 28
                            height: 36
                            radius: NeonStyle.radiusFull
                            color: (posBackend && posBackend.selectedCategory === modelData.id) ? NeonStyle.primaryColor : NeonStyle.surfaceColor
                            border.color: (posBackend && posBackend.selectedCategory === modelData.id) ? "transparent" : NeonStyle.borderColor

                            Text {
                                id: pillCatText
                                anchors.centerIn: parent
                                text: modelData.name
                                color: (posBackend && posBackend.selectedCategory === modelData.id) ? "white" : NeonStyle.textColor
                                font.bold: true
                                font.pixelSize: 14
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: if (posBackend) posBackend.filterByCategory(modelData.id)
                            }
                        }
                    }
                }
            }

            // ── PRODUCT GRID ──────────────────────────────────────────────────
            GridView {
                id: productGrid
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                cellWidth: Math.floor(width / Math.max(1, Math.floor(width / 195)))
                cellHeight: 210

                model: posBackend ? posBackend.productsModel : []

                // Empty state
                Text {
                    anchors.centerIn: parent
                    text: "No products found"
                    color: NeonStyle.textMuted
                    font.pixelSize: 16
                    visible: productGrid.count === 0
                }

                delegate: Item {
                    id: delegateItem
                    required property var modelData
                    required property int index
                    width: productGrid.cellWidth
                    height: productGrid.cellHeight

                    Rectangle {
                        id: productCard
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: NeonStyle.radiusL
                        color: NeonStyle.surfaceColor
                        border.color: cardMouse.containsMouse ? NeonStyle.primaryColor : NeonStyle.borderColor
                        border.width: cardMouse.containsMouse ? 1.5 : 1

                        Behavior on border.color { ColorAnimation { duration: 120 } }
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutBack } }

                        // ── Avatar area ──────────────────────────────────────
                        Rectangle {
                            id: avatarBg
                            anchors.top: parent.top
                            anchors.left: parent.left
                            anchors.right: parent.right
                            height: parent.height * 0.52
                            // rounded top only
                            radius: NeonStyle.radiusL
                            color: root.avatarColors[delegateItem.index % root.avatarColors.length]

                            // Square fill at bottom to hide bottom radius
                            Rectangle {
                                anchors.bottom: parent.bottom
                                width: parent.width
                                height: parent.radius
                                color: parent.color
                            }

                            Text {
                                anchors.centerIn: parent
                                text: delegateItem.modelData.name.substring(0, 2).toUpperCase()
                                color: root.avatarTextColors[delegateItem.index % root.avatarTextColors.length]
                                font.pixelSize: 36
                                font.bold: true
                            }
                        }

                        // ── Info area ────────────────────────────────────────
                        ColumnLayout {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            anchors.top: avatarBg.bottom
                            anchors.margins: 12
                            spacing: 6

                            Text {
                                Layout.fillWidth: true
                                text: delegateItem.modelData.name
                                color: NeonStyle.textColor
                                font.pixelSize: 15
                                font.bold: true
                                elide: Text.ElideRight
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 0

                                Text {
                                    text: "TND " + Number(delegateItem.modelData.price).toFixed(3)
                                    color: NeonStyle.primaryColor
                                    font.bold: true
                                    font.pixelSize: 13
                                }

                                Item { Layout.fillWidth: true }

                                // Add button
                                Rectangle {
                                    width: 30; height: 30; radius: 15
                                    color: NeonStyle.accentColor

                                    Text {
                                        anchors.centerIn: parent
                                        text: "+"
                                        color: "white"
                                        font.bold: true
                                        font.pixelSize: 20
                                    }
                                }
                            }
                        }

                        // Full card click area
                        MouseArea {
                            id: cardMouse
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (posBackend) posBackend.addToCart(delegateItem.modelData.id)
                                productCard.scale = 0.95
                                scaleBack.restart()
                            }
                        }

                        Timer {
                            id: scaleBack
                            interval: 120
                            onTriggered: productCard.scale = 1.0
                        }
                    }
                }
            }
        }

        // ═══════════════════════════════════════════════════════════════════════
        // RIGHT PANEL — Current order
        // ═══════════════════════════════════════════════════════════════════════
        Rectangle {
            Layout.preferredWidth: 360
            Layout.fillHeight: true
            radius: NeonStyle.radiusL
            color: NeonStyle.surfaceColor
            border.color: NeonStyle.borderColor
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NeonStyle.spaceL
                spacing: NeonStyle.spaceM

                // ── Panel header ──────────────────────────────────────────────
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text {
                        text: "Current Order"
                        color: NeonStyle.textColor
                        font.pixelSize: 22
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    // Item count badge
                    Rectangle {
                        visible: posBackend && posBackend.cart && posBackend.cart.length > 0
                        width: Math.max(24, badgeText.implicitWidth + 12)
                        height: 24
                        radius: 12
                        color: NeonStyle.primaryColor

                        Text {
                            id: badgeText
                            anchors.centerIn: parent
                            text: posBackend ? posBackend.cart.length : "0"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 12
                        }
                    }
                }

                // Cashier row
                RowLayout {
                    spacing: 10
                    Rectangle {
                        width: 32; height: 32; radius: 16
                        color: NeonStyle.surfaceLightColor
                        Text { anchors.centerIn: parent; text: "👤"; font.pixelSize: 16 }
                    }
                    Text {
                        text: "Cashier Terminal"
                        color: NeonStyle.textMuted
                        font.bold: true
                        font.pixelSize: 13
                    }
                }

                Rectangle { height: 1; Layout.fillWidth: true; color: NeonStyle.borderColor }

                // ── CART LIST ─────────────────────────────────────────────────
                Item {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    // Empty cart state
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: !posBackend || !posBackend.cart || posBackend.cart.length === 0

                        Text { Layout.alignment: Qt.AlignHCenter; text: "🛒"; font.pixelSize: 40; opacity: 0.3 }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Cart is empty"
                            color: NeonStyle.textMuted
                            font.pixelSize: 14
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "Tap a product to add it"
                            color: NeonStyle.textMuted
                            font.pixelSize: 12
                        }
                    }

                    ListView {
                        id: cartView
                        anchors.fill: parent
                        clip: true
                        visible: posBackend && posBackend.cart && posBackend.cart.length > 0
                        model: posBackend ? posBackend.cart : []
                        spacing: 4

                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            width: cartView.width
                            height: 64
                            radius: NeonStyle.radiusM
                            color: NeonStyle.surfaceLightColor

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 10
                                spacing: 10

                                // Avatar
                                Rectangle {
                                    width: 42; height: 42; radius: 10
                                    color: root.avatarColors[index % root.avatarColors.length]
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.name.substring(0, 1)
                                        color: root.avatarTextColors[index % root.avatarTextColors.length]
                                        font.bold: true
                                        font.pixelSize: 18
                                    }
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 2
                                    Text { text: modelData.name; color: NeonStyle.textColor; font.bold: true; font.pixelSize: 14; elide: Text.ElideRight }
                                    Text {
                                        text: "TND " + Number(modelData.price).toFixed(3)
                                        color: NeonStyle.primaryColor
                                        font.bold: true
                                        font.pixelSize: 12
                                    }
                                }

                                // Quantity controls
                                RowLayout {
                                    spacing: 6

                                    Rectangle {
                                        width: 26; height: 26; radius: 13
                                        border.color: NeonStyle.borderColor
                                        color: minusHover.containsMouse ? NeonStyle.surfacePressed : "transparent"
                                        Text { anchors.centerIn: parent; text: "−"; color: NeonStyle.textColor; font.bold: true; font.pixelSize: 14 }
                                        MouseArea {
                                            id: minusHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (posBackend) posBackend.cartItemDecrement(index)
                                        }
                                    }

                                    Text {
                                        text: modelData.quantity
                                        color: NeonStyle.textColor
                                        font.bold: true
                                        font.pixelSize: 14
                                        Layout.preferredWidth: 22
                                        horizontalAlignment: Text.AlignHCenter
                                    }

                                    Rectangle {
                                        width: 26; height: 26; radius: 13
                                        color: plusHover.containsMouse ? NeonStyle.primaryDarkColor : NeonStyle.accentColor
                                        Behavior on color { ColorAnimation { duration: 100 } }
                                        Text { anchors.centerIn: parent; text: "+"; color: "white"; font.bold: true; font.pixelSize: 14 }
                                        MouseArea {
                                            id: plusHover
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: if (posBackend) posBackend.cartItemIncrement(index)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── TOTALS ────────────────────────────────────────────────────
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle { height: 1; Layout.fillWidth: true; color: NeonStyle.borderColor }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Subtotal"; color: NeonStyle.textMuted; font.pixelSize: 14 }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "TND " + (posBackend ? posBackend.total.toFixed(3) : "0.000")
                            color: NeonStyle.textColor
                            font.bold: true
                            font.pixelSize: 14
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "VAT (19%)"; color: NeonStyle.textMuted; font.pixelSize: 14 }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "TND " + (posBackend ? (posBackend.total * 0.19).toFixed(3) : "0.000")
                            color: NeonStyle.textMuted
                            font.pixelSize: 14
                        }
                    }

                    Rectangle { height: 1; Layout.fillWidth: true; color: NeonStyle.borderColor }

                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "Total"; color: NeonStyle.textColor; font.pixelSize: 20; font.bold: true }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: (posBackend ? posBackend.total.toFixed(3) : "0.000") + " TND"
                            color: NeonStyle.textColor
                            font.pixelSize: 20
                            font.bold: true
                        }
                    }
                }

                // ── CHECKOUT BUTTON ───────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: NeonStyle.radiusM
                    color: checkoutHover.containsMouse ? NeonStyle.primaryDarkColor : NeonStyle.primaryColor
                    opacity: (!posBackend || !posBackend.cart || posBackend.cart.length === 0) ? 0.5 : 1.0

                    Behavior on color { ColorAnimation { duration: 120 } }

                    Text {
                        anchors.centerIn: parent
                        text: "Continue →"
                        color: "white"
                        font.bold: true
                        font.pixelSize: 16
                    }

                    MouseArea {
                        id: checkoutHover
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        enabled: posBackend && posBackend.cart && posBackend.cart.length > 0
                        onClicked: if (posBackend) posBackend.checkout()
                    }
                }
            }
        }
    }
}
