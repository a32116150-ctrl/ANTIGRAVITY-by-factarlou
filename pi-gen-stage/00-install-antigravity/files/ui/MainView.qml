import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ApplicationWindow {
    id: window
    visible: true
    width: 1920
    height: 1080
    title: "Antigravity POS"
    color: "#121212"

    property bool backendReady: backend !== undefined && backend !== null
    property int currentCategoryId: 0
    property string currentCategoryName: "All"

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: backendReady ? mainScreen : null
    }

    Component {
        id: mainScreen
        Rectangle {
            color: "#121212"

            TextField {
                id: scannerInput
                width: 0; height: 0; opacity: 0; 
                focus: backendReady ? (backend ? backend.scannerEnabled : true) : false
                onTextChanged: {
                    if (text.endsWith("\n") || text.endsWith("\r")) {
                        if (typeof scanner !== "undefined") scanner.handleInput(text)
                        text = ""
                    }
                }
            }

            // STATUS BAR
            Rectangle {
                id: statusBar
                width: parent.width; height: 40; color: "#000000"; z: 10
                RowLayout {
                    anchors.fill: parent; anchors.leftMargin: 20; anchors.rightMargin: 20
                    Text {
                        text: "PRINTER: " + (backendReady ? (backend.printerOnline ? "ONLINE" : "OFFLINE") : "LOADING")
                        color: backendReady && backend.printerOnline ? "#00e676" : "#ff5252"
                        font.pixelSize: 14; font.weight: Font.Bold
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: Qt.formatDateTime(new Date(), "dd MMM yyyy | hh:mm:ss")
                        color: "#888888"; font.pixelSize: 14
                    }
                }
            }

            RowLayout {
                anchors.fill: parent; anchors.topMargin: 40; spacing: 0

                // LEFT: Cart
                Rectangle {
                    Layout.fillHeight: true; Layout.preferredWidth: parent.width * 0.4
                    color: "#1e1e1e"; border.color: "#333333"

                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 20; spacing: 15
                        Text { text: "Active Cart"; color: "white"; font.pixelSize: 32; font.weight: Font.Bold }

                        ListView {
                            id: cartList
                            Layout.fillWidth: true; Layout.fillHeight: true; clip: true
                            model: backendReady ? backend.cart : []
                            spacing: 10
                            delegate: Rectangle {
                                width: cartList.width; height: 85; color: "#2a2a2a"; radius: 8
                                RowLayout {
                                    anchors.fill: parent; anchors.margins: 15
                                    Column {
                                        Layout.fillWidth: true
                                        Text { text: (modelData.name || "Unknown"); color: "white"; font.pixelSize: 20; font.weight: Font.Medium }
                                        Text { text: (modelData.quantity || 1) + " x " + (modelData.price || 0).toFixed(3); color: "#888888"; font.pixelSize: 14 }
                                    }
                                    Text {
                                        text: ((modelData.price || 0) * (modelData.quantity || 1)).toFixed(3) + " TND"
                                        color: "#00e676"; font.pixelSize: 20; font.weight: Font.Bold
                                    }
                                    Button {
                                        text: "✕"
                                        onClicked: backend.remove_from_cart(modelData.id)
                                        background: Rectangle { color: "transparent" }
                                        contentItem: Text { text: "✕"; color: "#ff5252"; font.pixelSize: 20; font.weight: Font.Bold }
                                    }
                                }
                            }
                        }

                        Rectangle {
                            Layout.fillWidth: true; height: 150; color: "#252525"; radius: 12
                            border.color: "#00e676"; border.width: 2
                            ColumnLayout {
                                anchors.centerIn: parent
                                Text { text: "TOTAL"; color: "#888888"; font.pixelSize: 20; Layout.alignment: Qt.AlignHCenter }
                                Text { text: (backendReady ? backend.total.toFixed(3) : "0.000") + " TND"; color: "white"; font.pixelSize: 64; font.weight: Font.Black; Layout.alignment: Qt.AlignHCenter }
                            }
                        }
                    }
                }

                // RIGHT: Grid
                Rectangle {
                    Layout.fillHeight: true; Layout.fillWidth: true; color: "#121212"
                    ColumnLayout {
                        anchors.fill: parent; anchors.margins: 40; spacing: 30
                        RowLayout {
                            Layout.fillWidth: true; spacing: 20
                            Text { text: "ANTIGRAVITY"; color: "#00e676"; font.pixelSize: 40; font.weight: Font.Black }
                            TextField {
                                id: manualSearch; Layout.fillWidth: true; placeholderText: "Search..."; font.pixelSize: 20; color: "white"
                                background: Rectangle { color: "#1e1e1e"; radius: 10; border.color: "#333333" }
                                onAccepted: { if (backendReady) backend.search_product(text); text = ""; scannerInput.forceActiveFocus() }
                            }
                            Button {
                                id: inventoryBtn
                                text: "Inventory"
                                onClicked: {
                                    if (backendReady) {
                                        backend.changeView("inventory")
                                        stackView.push(Qt.resolvedUrl("InventoryView.qml"))
                                    }
                                }
                                background: Rectangle { color: "#333333"; radius: 10 }
                                contentItem: Text { text: "📦 INVENTORY"; color: "white"; font.weight: Font.Bold; padding: 15 }
                            }
                        }

                        // Category Tab Bar
                        ScrollView {
                            Layout.fillWidth: true; height: 60; contentWidth: categoryRow.width; clip: true
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
                            Row {
                                id: categoryRow; spacing: 10
                                
                                Button {
                                    text: "ALL"
                                    onClicked: { currentCategoryId = 0; currentCategoryName = "All" }
                                    background: Rectangle {
                                        color: currentCategoryId === 0 ? "#00e676" : "#1e1e1e"
                                        radius: 20; border.color: "#333333"
                                    }
                                    contentItem: Text { text: "ALL"; color: currentCategoryId === 0 ? "black" : "white"; font.weight: Font.Bold; padding: 10 }
                                }

                                Repeater {
                                    model: backendReady ? backend.categories : []
                                    Button {
                                        text: modelData.name.toUpperCase()
                                        onClicked: { currentCategoryId = modelData.id; currentCategoryName = modelData.name }
                                        background: Rectangle {
                                            color: currentCategoryId === modelData.id ? "#00e676" : "#1e1e1e"
                                            radius: 20; border.color: "#333333"
                                        }
                                        contentItem: Text { text: modelData.name.toUpperCase(); color: currentCategoryId === modelData.id ? "black" : "white"; font.weight: Font.Bold; padding: 10 }
                                    }
                                }
                            }
                        }

                        GridLayout {
                            columns: 3; Layout.fillWidth: true; Layout.fillHeight: true; columnSpacing: 20; rowSpacing: 20
                            Repeater {
                                model: {
                                    if (!backendReady || !backend.inventory) return [];
                                    var filtered = backend.inventory;
                                    if (currentCategoryId !== 0) {
                                        filtered = filtered.filter(function(i) { return i.category_id === currentCategoryId; });
                                    }
                                    return filtered.slice(0, 9);
                                }
                                Button {
                                    Layout.fillWidth: true; Layout.fillHeight: true
                                    onClicked: if (backendReady) backend.add_to_cart(modelData)
                                    contentItem: Column {
                                        anchors.centerIn: parent; spacing: 5
                                        Text { text: (modelData.name || ""); color: "white"; font.pixelSize: 22; font.weight: Font.Bold; anchors.horizontalCenter: parent.horizontalCenter }
                                        Text { text: (modelData.price || 0).toFixed(3) + " TND"; color: "#00e676"; font.pixelSize: 18; anchors.horizontalCenter: parent.horizontalCenter }
                                    }
                                    background: Rectangle {
                                        color: parent.pressed ? "#00c853" : "#1e1e1e"
                                        radius: 15; border.color: (modelData.stock || 0) < 10 ? "#ff5252" : "#333333"
                                    }
                                }
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true; height: 120; spacing: 20
                            Button {
                                Layout.fillWidth: true; Layout.preferredHeight: 100
                                onClicked: if (backendReady) backend.clear_cart()
                                contentItem: Text { text: "🗑 CLEAR"; color: "white"; font.pixelSize: 24; font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { color: "#d32f2f"; radius: 15 }
                            }
                            Button {
                                Layout.fillWidth: true; Layout.preferredHeight: 100
                                onClicked: if (backendReady) backend.checkout("CASH")
                                contentItem: Text { text: "✅ PAY CASH"; color: "black"; font.pixelSize: 24; font.weight: Font.Bold; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter }
                                background: Rectangle { color: "#00e676"; radius: 15 }
                            }
                        }
                    }
                }
            }
        }
    }
}
