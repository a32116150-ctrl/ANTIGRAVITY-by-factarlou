import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import "styles"
import "components"

Rectangle {
    id: root
    color: NeonStyle.backgroundColor

    // ── Pull latest summary on load and whenever a checkout completes ──
    Component.onCompleted: {
        if (posBackend) posBackend.request_daily_summary()
    }

    // React to revenue updates emitted by the backend after every checkout
    Connections {
        target: posBackend
        function onDailySummaryChanged(data) {
            // Force re-read — data is already the new dict
            dailyRevText.text   = Number(data.revenue || 0).toFixed(3) + " TND"
            txnCountText.text   = String(data.count   || 0)
            vatText.text        = Number(data.vat     || 0).toFixed(3) + " TND"
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: NeonStyle.spaceL
        spacing: NeonStyle.spaceL

        // ── HEADER ──────────────────────────────────────────────────────────
        ColumnLayout {
            spacing: 2
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

        // ── STAT CARDS ───────────────────────────────────────────────────────
        RowLayout {
            spacing: NeonStyle.spaceM
            Layout.fillWidth: true

            // Daily Revenue
            Rectangle {
                Layout.fillWidth: true
                height: 110
                radius: NeonStyle.radiusM
                color: NeonStyle.surfaceColor
                border.color: NeonStyle.borderColor
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "DAILY REVENUE"
                        color: NeonStyle.textSecondaryColor
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 0.8
                    }
                    Text {
                        id: dailyRevText
                        Layout.alignment: Qt.AlignHCenter
                        text: ((posBackend && posBackend.dailySummary)
                               ? Number(posBackend.dailySummary.revenue || 0).toFixed(3)
                               : "0.000") + " TND"
                        color: NeonStyle.primaryColor
                        font.pixelSize: 28
                        font.bold: true
                    }
                }
            }

            // Transactions
            Rectangle {
                Layout.fillWidth: true
                height: 110
                radius: NeonStyle.radiusM
                color: NeonStyle.surfaceColor
                border.color: NeonStyle.borderColor
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "TRANSACTIONS"
                        color: NeonStyle.textSecondaryColor
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 0.8
                    }
                    Text {
                        id: txnCountText
                        Layout.alignment: Qt.AlignHCenter
                        text: (posBackend && posBackend.dailySummary)
                              ? String(posBackend.dailySummary.count || 0)
                              : "0"
                        color: NeonStyle.accentColor
                        font.pixelSize: 28
                        font.bold: true
                    }
                }
            }

            // VAT Collected
            Rectangle {
                Layout.fillWidth: true
                height: 110
                radius: NeonStyle.radiusM
                color: NeonStyle.surfaceColor
                border.color: NeonStyle.borderColor
                border.width: 1

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 6
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: "VAT COLLECTED"
                        color: NeonStyle.textSecondaryColor
                        font.pixelSize: 11
                        font.bold: true
                        font.letterSpacing: 0.8
                    }
                    Text {
                        id: vatText
                        Layout.alignment: Qt.AlignHCenter
                        text: ((posBackend && posBackend.dailySummary)
                               ? Number(posBackend.dailySummary.vat || 0).toFixed(3)
                               : "0.000") + " TND"
                        color: NeonStyle.greenColor
                        font.pixelSize: 28
                        font.bold: true
                    }
                }
            }
        }

        // ── LOW STOCK ALERTS ─────────────────────────────────────────────────
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: NeonStyle.radiusM
            color: NeonStyle.surfaceColor
            border.color: NeonStyle.borderColor
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: NeonStyle.spaceL
                spacing: NeonStyle.spaceM

                // Section header row — proper fillWidth on both sides
                RowLayout {
                    Layout.fillWidth: true
                    spacing: NeonStyle.spaceM

                    Text {
                        text: "LOW STOCK ALERTS"
                        color: NeonStyle.textColor
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Rectangle {
                        width: actionLabel.implicitWidth + 24
                        height: 30
                        radius: 15
                        color: NeonStyle.errorColor
                        visible: {
                            if (!posBackend || !posBackend.productsModel) return false
                            for (var i = 0; i < posBackend.productsModel.length; i++) {
                                if (posBackend.productsModel[i].stock <= 5) return true
                            }
                            return false
                        }
                        Text {
                            id: actionLabel
                            anchors.centerIn: parent
                            text: "Action Required"
                            color: "white"
                            font.bold: true
                            font.pixelSize: 12
                        }
                    }
                }

                // Divider
                Rectangle { Layout.fillWidth: true; height: 1; color: NeonStyle.borderColor }

                // Stock alert list
                ListView {
                    id: stockList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 6
                    model: posBackend ? posBackend.productsModel : []

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        // Only show items with stock ≤ 5 (including negatives)
                        width: stockList.width
                        height: modelData.stock <= 5 ? 48 : 0
                        visible: modelData.stock <= 5
                        color: modelData.stock <= 0
                               ? NeonStyle.errorColor + "12"
                               : NeonStyle.warningColor + "12"
                        radius: NeonStyle.radiusS

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            anchors.topMargin: 0
                            anchors.bottomMargin: 0
                            visible: parent.visible
                            spacing: NeonStyle.spaceM

                            // Status dot
                            Rectangle {
                                width: 8; height: 8; radius: 4
                                color: modelData.stock <= 0 ? NeonStyle.errorColor : NeonStyle.warningColor
                            }

                            Text {
                                text: modelData.name
                                color: NeonStyle.textColor
                                font.bold: true
                                font.pixelSize: 14
                                Layout.fillWidth: true
                            }

                            // Stock badge
                            Rectangle {
                                width: stockBadge.implicitWidth + 20
                                height: 26
                                radius: 13
                                color: modelData.stock <= 0
                                       ? NeonStyle.errorColor + "20"
                                       : NeonStyle.warningColor + "20"

                                Text {
                                    id: stockBadge
                                    anchors.centerIn: parent
                                    text: modelData.stock <= 0
                                          ? "OUT OF STOCK"
                                          : "Only " + modelData.stock + " left"
                                    color: modelData.stock <= 0
                                           ? NeonStyle.errorColor
                                           : NeonStyle.warningColor
                                    font.bold: true
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }

                    // All-healthy empty state
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 6
                        visible: stockList.count === 0 || !hasLowStock()
                        Text { Layout.alignment: Qt.AlignHCenter; text: "✅"; font.pixelSize: 32 }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: "All stock levels are healthy"
                            color: NeonStyle.textMuted
                            font.pixelSize: 14
                        }
                    }
                }
            }
        }
    }

    // Helper: returns true if any product has stock ≤ 5
    function hasLowStock() {
        if (!posBackend || !posBackend.productsModel) return false
        for (var i = 0; i < posBackend.productsModel.length; i++) {
            if (posBackend.productsModel[i].stock <= 5) return true
        }
        return false
    }
}
