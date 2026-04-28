import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import "styles"
import "components"

Rectangle {
    id: root
    color: NeonStyle.backgroundColor

    // ── Column widths — single source of truth so header & rows always match ──
    readonly property int colBarcode:  160
    readonly property int colStock:     80
    readonly property int colPrice:    110
    readonly property int colActions:  100
    readonly property int rowPad:       20   // left/right padding inside each row

    Component.onCompleted: {
        if (posBackend) posBackend.refreshInventory()
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: NeonStyle.spaceL
        spacing: NeonStyle.spaceM

        // ── PAGE HEADER ───────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: NeonStyle.spaceM

            ColumnLayout {
                spacing: 3
                Text { text: "STOCK MANAGEMENT"; color: NeonStyle.textColor; font.pixelSize: 24; font.bold: true }
                Text { text: "Monitor and manage your product inventory levels"; color: NeonStyle.textMuted; font.pixelSize: 14 }
            }

            Item { Layout.fillWidth: true }

            // Search
            Rectangle {
                width: 240; height: 40
                radius: NeonStyle.radiusM
                color: NeonStyle.surfaceColor
                border.color: searchIn.activeFocus ? NeonStyle.primaryColor : NeonStyle.borderColor
                border.width: searchIn.activeFocus ? 2 : 1
                Behavior on border.color { ColorAnimation { duration: 120 } }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 10; spacing: 6
                    Text { text: "🔍"; font.pixelSize: 13; opacity: 0.5 }
                    TextInput {
                        id: searchIn
                        Layout.fillWidth: true
                        font.pixelSize: 14; color: NeonStyle.textColor
                        onTextChanged: if (posBackend) posBackend.searchProducts(text)
                        Text { anchors.fill: parent; text: "Search products…"; color: NeonStyle.textMuted; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; visible: parent.text === "" }
                    }
                }
            }

            // ADD PRODUCT button
            Rectangle {
                width: 140; height: 40; radius: NeonStyle.radiusM
                color: addHov.containsMouse ? "#059669" : NeonStyle.greenColor
                Behavior on color { ColorAnimation { duration: 110 } }
                Text { anchors.centerIn: parent; text: "＋  ADD PRODUCT"; color: "white"; font.bold: true; font.pixelSize: 13 }
                MouseArea { id: addHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: { clearAddForm(); addDialog.open() } }
            }
        }

        // ── TAB BAR ───────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: 0

            Repeater {
                model: ["Products", "Categories"]
                Rectangle {
                    required property string modelData
                    required property int index
                    width: 140; height: 38
                    color: "transparent"

                    Rectangle {
                        anchors.bottom: parent.bottom
                        width: parent.width; height: 2
                        color: tabBar.currentIndex === index ? NeonStyle.primaryColor : "transparent"
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: modelData
                        color: tabBar.currentIndex === index ? NeonStyle.primaryColor : NeonStyle.textMuted
                        font.bold: tabBar.currentIndex === index
                        font.pixelSize: 14
                        Behavior on color { ColorAnimation { duration: 150 } }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: tabBar.currentIndex = index
                    }
                }
            }

            Item { Layout.fillWidth: true; height: 1 }
        }

        // ── TAB CONTENT ──────────────────────────────────────────────────────
        Item {
            id: tabBar
            property int currentIndex: 0
            Layout.fillWidth: true
            Layout.fillHeight: true

            // ════════════════════════════════════════════════════════════════
            // TAB 0 — PRODUCTS
            // ════════════════════════════════════════════════════════════════
            ColumnLayout {
                anchors.fill: parent
                spacing: 0
                visible: tabBar.currentIndex === 0

                // ── TABLE HEADER ─────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    height: 40
                    radius: NeonStyle.radiusS
                    color: NeonStyle.surfaceLightColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: root.rowPad
                        anchors.rightMargin: root.rowPad
                        spacing: 0

                        Text { text: "BARCODE";      color: NeonStyle.textMuted; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; Layout.preferredWidth: root.colBarcode }
                        Text { text: "PRODUCT NAME"; color: NeonStyle.textMuted; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; Layout.fillWidth: true }
                        Text { text: "CATEGORY";     color: NeonStyle.textMuted; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; Layout.preferredWidth: 100 }
                        Text { text: "STOCK";        color: NeonStyle.textMuted; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; Layout.preferredWidth: root.colStock;   horizontalAlignment: Text.AlignHCenter }
                        Text { text: "UNIT PRICE";   color: NeonStyle.textMuted; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; Layout.preferredWidth: root.colPrice;   horizontalAlignment: Text.AlignRight }
                        Text { text: "ACTIONS";      color: NeonStyle.textMuted; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; Layout.preferredWidth: root.colActions; horizontalAlignment: Text.AlignRight }
                    }
                }

                Item { height: 8 }

                // ── PRODUCT LIST ─────────────────────────────────────────────
                ListView {
                    id: invList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: posBackend ? posBackend.productsModel : []

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: invList.width
                        height: 56
                        radius: NeonStyle.radiusM
                        color: rowHover.containsMouse ? NeonStyle.surfaceLightColor : NeonStyle.surfaceColor
                        border.color: NeonStyle.borderColor
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }

                        RowLayout {
                            // Match header margins EXACTLY — same rowPad, no border offset
                            anchors.fill: parent
                            anchors.leftMargin: root.rowPad
                            anchors.rightMargin: root.rowPad
                            spacing: 0

                            // Barcode
                            Text {
                                text: modelData.barcode || "—"
                                color: NeonStyle.textMuted
                                font.pixelSize: 13
                                Layout.preferredWidth: root.colBarcode
                                elide: Text.ElideRight
                            }

                            // Name
                            Text {
                                text: modelData.name
                                color: NeonStyle.textColor
                                font.pixelSize: 15
                                font.bold: true
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            // Category pill
                            Rectangle {
                                Layout.preferredWidth: 100
                                height: 22; radius: 11
                                color: NeonStyle.primaryColor + "18"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.category_name || "General"
                                    color: NeonStyle.primaryColor
                                    font.pixelSize: 11; font.bold: true
                                    elide: Text.ElideRight
                                }
                            }

                            // Stock badge (centered)
                            Item {
                                Layout.preferredWidth: root.colStock

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: stockTxt.implicitWidth + 18; height: 26; radius: 13
                                    color: modelData.stock <= 5 ? NeonStyle.errorColor + "15" : NeonStyle.greenColor + "15"

                                    Text {
                                        id: stockTxt
                                        anchors.centerIn: parent
                                        text: modelData.stock
                                        color: modelData.stock <= 5 ? NeonStyle.errorColor : NeonStyle.greenColor
                                        font.bold: true; font.pixelSize: 13
                                    }
                                }
                            }

                            // Price (right-aligned)
                            Text {
                                text: Number(modelData.price).toFixed(3)
                                color: NeonStyle.primaryColor
                                font.pixelSize: 14; font.bold: true
                                Layout.preferredWidth: root.colPrice
                                horizontalAlignment: Text.AlignRight
                            }

                            // Actions
                            RowLayout {
                                Layout.preferredWidth: root.colActions
                                spacing: 6
                                layoutDirection: Qt.RightToLeft

                                // Delete
                                Rectangle {
                                    width: 32; height: 32; radius: 8
                                    color: delHov.containsMouse ? NeonStyle.errorColor + "25" : "transparent"
                                    border.color: delHov.containsMouse ? NeonStyle.errorColor : NeonStyle.borderColor
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text { anchors.centerIn: parent; text: "🗑"; font.pixelSize: 14 }
                                    MouseArea { id: delHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: if (posBackend) posBackend.deleteProduct(modelData.id) }
                                }

                                // Edit
                                Rectangle {
                                    width: 32; height: 32; radius: 8
                                    color: editHov.containsMouse ? NeonStyle.primaryColor + "20" : "transparent"
                                    border.color: editHov.containsMouse ? NeonStyle.primaryColor : NeonStyle.borderColor
                                    border.width: 1
                                    Behavior on color { ColorAnimation { duration: 100 } }
                                    Text { anchors.centerIn: parent; text: "✎"; font.pixelSize: 16; color: editHov.containsMouse ? NeonStyle.primaryColor : NeonStyle.textMuted }
                                    MouseArea {
                                        id: editHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            editProductId = modelData.id
                                            editName.text     = modelData.name
                                            editBarcode.text  = modelData.barcode || ""
                                            editPrice.text    = String(modelData.price)
                                            editStock.text    = String(modelData.stock)
                                            // select category in combo
                                            var catIdx = 0
                                            if (posBackend && posBackend.categoriesModel) {
                                                for (var i = 0; i < posBackend.categoriesModel.length; i++) {
                                                    if (posBackend.categoriesModel[i].id === modelData.category_id) { catIdx = i; break }
                                                }
                                            }
                                            editCatCombo.currentIndex = catIdx
                                            editDialog.open()
                                        }
                                    }
                                }
                            }
                        }

                        MouseArea { id: rowHover; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                    }

                    // Empty state
                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 8
                        visible: invList.count === 0
                        Text { Layout.alignment: Qt.AlignHCenter; text: "📦"; font.pixelSize: 40; opacity: 0.3 }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "No products found"; color: NeonStyle.textMuted; font.pixelSize: 15 }
                    }
                }
            }

            // ════════════════════════════════════════════════════════════════
            // TAB 1 — CATEGORIES
            // ════════════════════════════════════════════════════════════════
            ColumnLayout {
                anchors.fill: parent
                spacing: NeonStyle.spaceM
                visible: tabBar.currentIndex === 1

                // Add category row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: NeonStyle.spaceM

                    Rectangle {
                        Layout.fillWidth: true; height: 44
                        radius: NeonStyle.radiusM
                        color: NeonStyle.surfaceColor
                        border.color: newCatIn.activeFocus ? NeonStyle.primaryColor : NeonStyle.borderColor
                        border.width: newCatIn.activeFocus ? 2 : 1
                        Behavior on border.color { ColorAnimation { duration: 120 } }

                        TextInput {
                            id: newCatIn
                            anchors.fill: parent; anchors.margins: 14
                            font.pixelSize: 14; color: NeonStyle.textColor
                            Keys.onReturnPressed: addCat()
                            Text { anchors.fill: parent; text: "New category name…"; color: NeonStyle.textMuted; font.pixelSize: 14; verticalAlignment: Text.AlignVCenter; visible: parent.text === "" }
                        }
                    }

                    Rectangle {
                        width: 130; height: 44; radius: NeonStyle.radiusM
                        color: catAddHov.containsMouse ? NeonStyle.primaryDarkColor : NeonStyle.primaryColor
                        Behavior on color { ColorAnimation { duration: 110 } }
                        Text { anchors.centerIn: parent; text: "＋  Add Category"; color: "white"; font.bold: true; font.pixelSize: 13 }
                        MouseArea { id: catAddHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: addCat() }
                    }
                }

                // Category list
                ListView {
                    id: catList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 8
                    model: posBackend ? posBackend.categoriesModel : []

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: catList.width
                        height: 56
                        radius: NeonStyle.radiusM
                        color: NeonStyle.surfaceColor
                        border.color: NeonStyle.borderColor
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            Rectangle {
                                width: 36; height: 36; radius: 10
                                color: NeonStyle.primaryColor + "18"
                                Text { anchors.centerIn: parent; text: "🏷️"; font.pixelSize: 18 }
                            }

                            Text {
                                Layout.fillWidth: true
                                text: modelData.name
                                color: NeonStyle.textColor
                                font.bold: true
                                font.pixelSize: 15
                            }

                            // Product count badge
                            Rectangle {
                                width: productCountTxt.implicitWidth + 20; height: 26; radius: 13
                                color: NeonStyle.surfaceLightColor
                                Text {
                                    id: productCountTxt
                                    anchors.centerIn: parent
                                    text: (modelData.product_count || "0") + " products"
                                    color: NeonStyle.textMuted; font.pixelSize: 12
                                }
                            }

                            // Delete category
                            Rectangle {
                                width: 32; height: 32; radius: 8
                                color: catDelHov.containsMouse ? NeonStyle.errorColor + "20" : "transparent"
                                border.color: catDelHov.containsMouse ? NeonStyle.errorColor : NeonStyle.borderColor
                                border.width: 1
                                Behavior on color { ColorAnimation { duration: 100 } }
                                Text { anchors.centerIn: parent; text: "🗑"; font.pixelSize: 14 }
                                MouseArea {
                                    id: catDelHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: if (posBackend) posBackend.deleteCategory(modelData.id)
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        anchors.centerIn: parent; spacing: 8
                        visible: catList.count === 0
                        Text { Layout.alignment: Qt.AlignHCenter; text: "🏷️"; font.pixelSize: 40; opacity: 0.3 }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "No categories yet"; color: NeonStyle.textMuted; font.pixelSize: 15 }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Create one above to organise your products"; color: NeonStyle.textMuted; font.pixelSize: 12 }
                    }
                }
            }
        }
    }

    // ─── State for edit dialog ────────────────────────────────────────────────
    property int editProductId: -1

    // ── helper functions ──────────────────────────────────────────────────────
    function clearAddForm() {
        addName.text = ""; addBarcode.text = ""
        addPrice.text = ""; addStock.text = ""
        addCatCombo.currentIndex = 0
    }

    function addCat() {
        var n = newCatIn.text.trim()
        if (n !== "" && posBackend) {
            posBackend.addCategory(n)
            newCatIn.text = ""
        }
    }

    // ── Shared field label component ──────────────────────────────────────────
    component FieldLabel: Text {
        color: NeonStyle.textMuted
        font.pixelSize: 11
        font.bold: true
        font.letterSpacing: 0.5
    }

    // ── Category combo helper ─────────────────────────────────────────────────
    component CatCombo: ComboBox {
        Layout.fillWidth: true
        model: posBackend ? posBackend.categoriesModel : []
        textRole: "name"
        valueRole: "id"

        contentItem: Text {
            leftPadding: 12
            text: parent.displayText
            color: NeonStyle.textColor
            font.pixelSize: 14
            verticalAlignment: Text.AlignVCenter
        }

        background: Rectangle {
            radius: NeonStyle.radiusM
            color: NeonStyle.surfaceLightColor
            border.color: parent.activeFocus ? NeonStyle.primaryColor : NeonStyle.borderColor
            border.width: parent.activeFocus ? 2 : 1
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // ADD PRODUCT DIALOG
    // ════════════════════════════════════════════════════════════════════════
    Dialog {
        id: addDialog
        anchors.centerIn: parent
        width: 440
        modal: true
        padding: 0

        background: Rectangle {
            radius: NeonStyle.radiusL
            color: NeonStyle.surfaceColor
            border.color: NeonStyle.borderColor
            border.width: 1
        }

        // Custom content — avoids Dialog header/content margin fights
        contentItem: ColumnLayout {
            spacing: 0

            // Dialog header
            Rectangle {
                Layout.fillWidth: true
                height: 60
                radius: NeonStyle.radiusL
                color: NeonStyle.surfaceLightColor
                // square bottom corners
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: parent.radius; color: parent.color }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 20
                    Text { text: "NEW PRODUCT"; color: NeonStyle.textColor; font.bold: true; font.pixelSize: 16; font.letterSpacing: 0.5; Layout.fillWidth: true }
                    Rectangle {
                        width: 28; height: 28; radius: 14; color: closeAdd.containsMouse ? NeonStyle.surfacePressed : "transparent"
                        Text { anchors.centerIn: parent; text: "✕"; color: NeonStyle.textMuted; font.pixelSize: 14 }
                        MouseArea { id: closeAdd; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: addDialog.close() }
                    }
                }
            }

            // Form body
            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 24
                spacing: NeonStyle.spaceM

                FieldLabel { text: "PRODUCT NAME" }
                NeonTextField { id: addName; placeholderText: "e.g. Espresso"; Layout.fillWidth: true }

                FieldLabel { text: "BARCODE" }
                NeonTextField { id: addBarcode; placeholderText: "Scan or type barcode"; Layout.fillWidth: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NeonStyle.spaceM

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6
                        FieldLabel { text: "PRICE (TND)" }
                        NeonTextField { id: addPrice; placeholderText: "0.000"; Layout.fillWidth: true }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6
                        FieldLabel { text: "INITIAL STOCK" }
                        NeonTextField { id: addStock; placeholderText: "0"; Layout.fillWidth: true }
                    }
                }

                FieldLabel { text: "CATEGORY" }
                CatCombo { id: addCatCombo }

                // Action buttons
                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: NeonStyle.spaceM

                    Rectangle {
                        Layout.fillWidth: true; height: 44; radius: NeonStyle.radiusM
                        color: cnclAdd.containsMouse ? NeonStyle.surfacePressed : NeonStyle.surfaceLightColor
                        border.color: NeonStyle.borderColor; border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.centerIn: parent; text: "Cancel"; color: NeonStyle.textColor; font.bold: true; font.pixelSize: 14 }
                        MouseArea { id: cnclAdd; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: addDialog.close() }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 44; radius: NeonStyle.radiusM
                        color: confirmAdd.containsMouse ? NeonStyle.primaryDarkColor : NeonStyle.primaryColor
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.centerIn: parent; text: "Add Product"; color: "white"; font.bold: true; font.pixelSize: 14 }
                        MouseArea {
                            id: confirmAdd; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (posBackend) {
                                    var catId = addCatCombo.currentValue || 1
                                    posBackend.addProduct(addName.text, addBarcode.text, parseFloat(addPrice.text) || 0, parseInt(addStock.text) || 0, catId)
                                }
                                addDialog.close()
                            }
                        }
                    }
                }
            }
        }
    }

    // ════════════════════════════════════════════════════════════════════════
    // EDIT PRODUCT DIALOG
    // ════════════════════════════════════════════════════════════════════════
    Dialog {
        id: editDialog
        anchors.centerIn: parent
        width: 440
        modal: true
        padding: 0

        background: Rectangle {
            radius: NeonStyle.radiusL
            color: NeonStyle.surfaceColor
            border.color: NeonStyle.borderColor
            border.width: 1
        }

        contentItem: ColumnLayout {
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                height: 60
                radius: NeonStyle.radiusL
                color: NeonStyle.surfaceLightColor
                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: parent.radius; color: parent.color }

                RowLayout {
                    anchors.fill: parent; anchors.margins: 20
                    Text { text: "EDIT PRODUCT"; color: NeonStyle.textColor; font.bold: true; font.pixelSize: 16; font.letterSpacing: 0.5; Layout.fillWidth: true }
                    Rectangle {
                        width: 28; height: 28; radius: 14; color: closeEdit.containsMouse ? NeonStyle.surfacePressed : "transparent"
                        Text { anchors.centerIn: parent; text: "✕"; color: NeonStyle.textMuted; font.pixelSize: 14 }
                        MouseArea { id: closeEdit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: editDialog.close() }
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.margins: 24
                spacing: NeonStyle.spaceM

                FieldLabel { text: "PRODUCT NAME" }
                NeonTextField { id: editName; Layout.fillWidth: true }

                FieldLabel { text: "BARCODE" }
                NeonTextField { id: editBarcode; Layout.fillWidth: true }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: NeonStyle.spaceM

                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6
                        FieldLabel { text: "PRICE (TND)" }
                        NeonTextField { id: editPrice; Layout.fillWidth: true }
                    }
                    ColumnLayout {
                        Layout.fillWidth: true; spacing: 6
                        FieldLabel { text: "STOCK" }
                        NeonTextField { id: editStock; Layout.fillWidth: true }
                    }
                }

                FieldLabel { text: "CATEGORY" }
                CatCombo { id: editCatCombo }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    spacing: NeonStyle.spaceM

                    Rectangle {
                        Layout.fillWidth: true; height: 44; radius: NeonStyle.radiusM
                        color: cnclEdit.containsMouse ? NeonStyle.surfacePressed : NeonStyle.surfaceLightColor
                        border.color: NeonStyle.borderColor; border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.centerIn: parent; text: "Cancel"; color: NeonStyle.textColor; font.bold: true; font.pixelSize: 14 }
                        MouseArea { id: cnclEdit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: editDialog.close() }
                    }

                    Rectangle {
                        Layout.fillWidth: true; height: 44; radius: NeonStyle.radiusM
                        color: confirmEdit.containsMouse ? NeonStyle.primaryDarkColor : NeonStyle.primaryColor
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.centerIn: parent; text: "Save Changes"; color: "white"; font.bold: true; font.pixelSize: 14 }
                        MouseArea {
                            id: confirmEdit; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                if (posBackend) {
                                    var catId = editCatCombo.currentValue || 1
                                    posBackend.updateProduct(root.editProductId, editName.text, editBarcode.text, parseFloat(editPrice.text) || 0, parseInt(editStock.text) || 0, catId)
                                }
                                editDialog.close()
                            }
                        }
                    }
                }
            }
        }
    }
}
