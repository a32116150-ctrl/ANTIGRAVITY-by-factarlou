import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import "styles"
import "components"

Rectangle {
    id: root
    color: NeonStyle.backgroundColor

    // ─── ROOT LAYOUT ────────────────────────────────────────────────────────────
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: NeonStyle.spaceL
        spacing: NeonStyle.spaceL

        // ── HEADER ROW ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: NeonStyle.spaceM

            ColumnLayout {
                spacing: 4
                Text {
                    text: "SYSTEM SETTINGS"
                    color: NeonStyle.textColor
                    font.pixelSize: 28
                    font.bold: true
                    font.letterSpacing: 0.5
                }
                Text {
                    text: "Configure store preferences and hardware"
                    color: NeonStyle.textMuted
                    font.pixelSize: 14
                }
            }

            Item { Layout.fillWidth: true }

            // Save button – plain Rectangle so we don't fight NeonButton sizing
            Rectangle {
                width: 140; height: 44
                radius: NeonStyle.radiusM
                color: saveHover.containsMouse ? NeonStyle.primaryDarkColor : NeonStyle.primaryColor

                Behavior on color { ColorAnimation { duration: 120 } }

                Text {
                    anchors.centerIn: parent
                    text: "SAVE ALL"
                    color: "white"
                    font.bold: true
                    font.pixelSize: 13
                    font.letterSpacing: 1
                }
                MouseArea {
                    id: saveHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: saveAll()
                }
            }
        }

        // ── SCROLLABLE BODY ──────────────────────────────────────────────────────
        // FIX #1: contentWidth stops the horizontal scroll fight.
        // FIX #2: ColumnLayout width = parent.width, NOT root.width - 60.
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            contentWidth: availableWidth          // ← the key fix for horizontal jitter

            ColumnLayout {
                width: parent.width               // parent = ScrollView.contentItem
                spacing: NeonStyle.spaceM

                // ── CARD HELPER: styled Rectangle whose height = content + padding ──
                // We use plain Rectangles instead of NeonCard because NeonCard
                // loses its implicit height when children use anchors.fill.

                // ── 1. STORE IDENTIFICATION ──────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    // FIX #3: implicitHeight drives the card's height from its content.
                    implicitHeight: storeIdLayout.implicitHeight + NeonStyle.spaceL * 2
                    radius: NeonStyle.radiusL
                    color: NeonStyle.surfaceColor
                    border.color: NeonStyle.borderColor
                    border.width: 1

                    // Subtle left accent stripe
                    Rectangle {
                        width: 4; height: 20; radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: NeonStyle.spaceL
                        anchors.top: parent.top
                        anchors.topMargin: NeonStyle.spaceL
                        color: NeonStyle.primaryColor
                    }

                    ColumnLayout {
                        id: storeIdLayout
                        // FIX #4: position with x/y + explicit width, never anchors.fill
                        x: NeonStyle.spaceL
                        y: NeonStyle.spaceL
                        width: parent.width - NeonStyle.spaceL * 2
                        spacing: NeonStyle.spaceM

                        Text {
                            text: "STORE IDENTIFICATION"
                            color: NeonStyle.primaryColor
                            font.bold: true
                            font.pixelSize: 13
                            font.letterSpacing: 1.2
                            leftPadding: 14      // indent past the stripe
                        }

                        GridLayout {
                            Layout.fillWidth: true
                            columns: 2
                            columnSpacing: NeonStyle.spaceM
                            rowSpacing: NeonStyle.spaceM

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                Text { text: "STORE NAME"; color: NeonStyle.textMuted; font.pixelSize: 11; font.bold: true; font.letterSpacing: 0.5 }
                                NeonTextField {
                                    id: store_name
                                    Layout.fillWidth: true
                                    text: (posBackend && posBackend.settings) ? (posBackend.settings.store_name || "") : ""
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                Text { text: "TAX ID"; color: NeonStyle.textMuted; font.pixelSize: 11; font.bold: true; font.letterSpacing: 0.5 }
                                NeonTextField {
                                    id: store_tax_id
                                    Layout.fillWidth: true
                                    text: (posBackend && posBackend.settings) ? (posBackend.settings.store_tax_id || "") : ""
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                Text { text: "PHONE"; color: NeonStyle.textMuted; font.pixelSize: 11; font.bold: true; font.letterSpacing: 0.5 }
                                NeonTextField {
                                    id: store_phone
                                    Layout.fillWidth: true
                                    text: (posBackend && posBackend.settings) ? (posBackend.settings.store_phone || "") : ""
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                Text { text: "ADDRESS"; color: NeonStyle.textMuted; font.pixelSize: 11; font.bold: true; font.letterSpacing: 0.5 }
                                NeonTextField {
                                    id: store_address
                                    Layout.fillWidth: true
                                    text: (posBackend && posBackend.settings) ? (posBackend.settings.store_address || "") : ""
                                }
                            }
                        }
                    }
                }

                // ── 2. FISCAL & CURRENCY ─────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: fiscalLayout.implicitHeight + NeonStyle.spaceL * 2
                    radius: NeonStyle.radiusL
                    color: NeonStyle.surfaceColor
                    border.color: NeonStyle.borderColor
                    border.width: 1

                    Rectangle {
                        width: 4; height: 20; radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: NeonStyle.spaceL
                        anchors.top: parent.top
                        anchors.topMargin: NeonStyle.spaceL
                        color: NeonStyle.greenColor
                    }

                    ColumnLayout {
                        id: fiscalLayout
                        x: NeonStyle.spaceL
                        y: NeonStyle.spaceL
                        width: parent.width - NeonStyle.spaceL * 2
                        spacing: NeonStyle.spaceM

                        Text {
                            text: "FISCAL & CURRENCY"
                            color: NeonStyle.greenColor
                            font.bold: true
                            font.pixelSize: 13
                            font.letterSpacing: 1.2
                            leftPadding: 14
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: NeonStyle.spaceM

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                Text { text: "VAT (%)"; color: NeonStyle.textMuted; font.pixelSize: 11; font.bold: true; font.letterSpacing: 0.5 }
                                NeonTextField {
                                    id: tax_rate
                                    Layout.fillWidth: true
                                    text: (posBackend && posBackend.settings) ? (posBackend.settings.tax_rate || "19") : "19"
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                Text { text: "CURRENCY"; color: NeonStyle.textMuted; font.pixelSize: 11; font.bold: true; font.letterSpacing: 0.5 }
                                NeonTextField {
                                    id: currency
                                    Layout.fillWidth: true
                                    text: (posBackend && posBackend.settings) ? (posBackend.settings.currency || "TND") : "TND"
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 5
                                Text { text: "LOW STOCK ALERT"; color: NeonStyle.textMuted; font.pixelSize: 11; font.bold: true; font.letterSpacing: 0.5 }
                                NeonTextField {
                                    id: low_stock_threshold
                                    Layout.fillWidth: true
                                    text: (posBackend && posBackend.settings) ? (posBackend.settings.low_stock_threshold || "5") : "5"
                                }
                            }
                        }
                    }
                }

                // ── 3. SYSTEM ACTIONS ────────────────────────────────────────────
                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: actionsLayout.implicitHeight + NeonStyle.spaceL * 2
                    radius: NeonStyle.radiusL
                    color: NeonStyle.surfaceColor
                    border.color: NeonStyle.borderColor
                    border.width: 1

                    Rectangle {
                        width: 4; height: 20; radius: 2
                        anchors.left: parent.left
                        anchors.leftMargin: NeonStyle.spaceL
                        anchors.top: parent.top
                        anchors.topMargin: NeonStyle.spaceL
                        color: NeonStyle.accentColor
                    }

                    ColumnLayout {
                        id: actionsLayout
                        x: NeonStyle.spaceL
                        y: NeonStyle.spaceL
                        width: parent.width - NeonStyle.spaceL * 2
                        spacing: NeonStyle.spaceM

                        Text {
                            text: "SYSTEM ACTIONS"
                            color: NeonStyle.textColor
                            font.bold: true
                            font.pixelSize: 13
                            font.letterSpacing: 1.2
                            leftPadding: 14
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: NeonStyle.spaceM

                            // ── Action button component (inline) ──
                            Repeater {
                                model: [
                                    { icon: "🖨️", label: "TEST PRINTER" },
                                    { icon: "📡", label: "SCANNER INFO" },
                                    { icon: "💾", label: "DB BACKUP"    }
                                ]

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 64
                                    radius: NeonStyle.radiusM
                                    color: actionHover.containsMouse ? NeonStyle.surfacePressed : NeonStyle.surfaceLightColor
                                    border.color: NeonStyle.borderColor
                                    border.width: 1

                                    Behavior on color { ColorAnimation { duration: 100 } }

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: modelData.icon
                                            font.pixelSize: 22
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            text: modelData.label
                                            color: NeonStyle.textColor
                                            font.bold: true
                                            font.pixelSize: 11
                                            font.letterSpacing: 0.5
                                        }
                                    }

                                    MouseArea {
                                        id: actionHover
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                }
                            }
                        }
                    }
                }

                // ── STATUS MESSAGE ───────────────────────────────────────────────
                Text {
                    id: statusMsg
                    Layout.alignment: Qt.AlignHCenter
                    text: ""
                    color: NeonStyle.greenColor
                    font.pixelSize: 14
                    font.bold: true
                    visible: text !== ""

                    Timer {
                        id: clearTimer
                        interval: 3000
                        onTriggered: statusMsg.text = ""
                    }
                }

                Item { Layout.preferredHeight: NeonStyle.spaceL }
            }
        }
    }

    // ─── SAVE HANDLER ────────────────────────────────────────────────────────────
    function saveAll() {
        if (!posBackend) return
        posBackend.saveSettings({
            "store_name":           store_name.text,
            "store_tax_id":         store_tax_id.text,
            "store_phone":          store_phone.text,
            "store_address":        store_address.text,
            "tax_rate":             tax_rate.text,
            "currency":             currency.text,
            "low_stock_threshold":  low_stock_threshold.text
        })
        statusMsg.text = "✓ Settings saved successfully!"
        clearTimer.restart()
    }
}
