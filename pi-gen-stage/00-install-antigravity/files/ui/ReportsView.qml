import QtQuick 6.0
import QtQuick.Controls 6.0
import QtQuick.Layouts 6.0
import "styles"
import "components"

Rectangle {
    id: root
    color: NeonStyle.backgroundColor

    Component.onCompleted: {
        if (posBackend) {
            posBackend.request_daily_summary()
            posBackend.loadRecentInvoices()
        }
    }

    // Live-update when a new sale is recorded
    Connections {
        target: posBackend
        function onDailySummaryChanged(data) {
            revText.text  = Number(data.revenue || 0).toFixed(3)
            txnText.text  = String(data.count   || 0)
            vatText.text  = Number(data.vat     || 0).toFixed(3)
        }
        function onRecentInvoicesChanged(list) {
            // The ListView model binds reactively — nothing extra needed
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: NeonStyle.spaceL
        spacing: NeonStyle.spaceL

        // ── HEADER ──────────────────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true

            ColumnLayout {
                spacing: 2
                Text {
                    text: "ANALYTICS & REPORTS"
                    color: NeonStyle.textColor
                    font.pixelSize: 28
                    font.bold: true
                }
                Text {
                    text: "Track your business performance and transaction history"
                    color: NeonStyle.textSecondaryColor
                    font.pixelSize: 14
                }
            }

            Item { Layout.fillWidth: true }

            // Z-Report button
            Rectangle {
                width: 160; height: 44; radius: NeonStyle.radiusM
                color: zHov.containsMouse ? NeonStyle.primaryDarkColor : NeonStyle.primaryColor
                Behavior on color { ColorAnimation { duration: 110 } }
                Text { anchors.centerIn: parent; text: "🖨  Z-REPORT"; color: "white"; font.bold: true; font.pixelSize: 13 }
                MouseArea {
                    id: zHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: { if (posBackend) posBackend.print_z_report(posBackend.dailySummary) }
                }
            }
        }

        // ── TODAY'S STAT CARDS ───────────────────────────────────────────────
        RowLayout {
            Layout.fillWidth: true
            spacing: NeonStyle.spaceM

            Repeater {
                model: [
                    { label: "TODAY'S REVENUE", id: "rev",  color: NeonStyle.primaryColor,  suffix: " TND" },
                    { label: "TRANSACTIONS",    id: "txn",  color: NeonStyle.accentColor,   suffix: ""      },
                    { label: "VAT COLLECTED",   id: "vat",  color: NeonStyle.greenColor,    suffix: " TND" }
                ]

                Rectangle {
                    Layout.fillWidth: true
                    height: 100
                    radius: NeonStyle.radiusM
                    color: NeonStyle.surfaceColor
                    border.color: NeonStyle.borderColor
                    border.width: 1

                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 4

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: modelData.label
                            color: NeonStyle.textSecondaryColor
                            font.pixelSize: 11
                            font.bold: true
                            font.letterSpacing: 0.8
                        }

                        Text {
                            // id: modelData.id === "rev" ? revText : (modelData.id === "txn" ? txnText : vatText) // Invalid QML: id must be a literal
                            id: valueDisplay
                            Layout.alignment: Qt.AlignHCenter
                            text: {
                                var val = posBackend && posBackend.dailySummary
                                if (modelData.id === "rev")  return Number(val ? (val.revenue || 0) : 0).toFixed(3) + " TND"
                                if (modelData.id === "txn")  return String(val ? (val.count   || 0) : 0)
                                return Number(val ? (val.vat || 0) : 0).toFixed(3) + " TND"
                            }
                            color: modelData.color
                            font.pixelSize: 26
                            font.bold: true
                        }
                    }
                }
            }
        }

        // ── TRANSACTION HISTORY ──────────────────────────────────────────────
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

                // Section header
                RowLayout {
                    Layout.fillWidth: true

                    Text {
                        text: "TRANSACTION HISTORY"
                        color: NeonStyle.textColor
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Item { Layout.fillWidth: true }

                    Text {
                        text: "Last 100 invoices"
                        color: NeonStyle.textMuted
                        font.pixelSize: 12
                    }

                    Rectangle {
                        width: 28; height: 28; radius: 8
                        color: refreshHov.containsMouse ? NeonStyle.surfacePressed : NeonStyle.surfaceLightColor
                        border.color: NeonStyle.borderColor; border.width: 1
                        Behavior on color { ColorAnimation { duration: 100 } }
                        Text { anchors.centerIn: parent; text: "↻"; font.pixelSize: 16; color: NeonStyle.textMuted }
                        MouseArea {
                            id: refreshHov; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { if (posBackend) posBackend.loadRecentInvoices() }
                        }
                    }
                }

                // Table header
                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: NeonStyle.radiusS
                    color: NeonStyle.surfaceLightColor

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 0
                        Text { text: "DATE & TIME";   color: NeonStyle.textMuted; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; Layout.preferredWidth: 160 }
                        Text { text: "INVOICE ID";    color: NeonStyle.textMuted; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; Layout.fillWidth: true }
                        Text { text: "VAT";           color: NeonStyle.textMuted; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; Layout.preferredWidth: 110; horizontalAlignment: Text.AlignRight }
                        Text { text: "TOTAL";         color: NeonStyle.textMuted; font.bold: true; font.pixelSize: 11; font.letterSpacing: 0.5; Layout.preferredWidth: 130; horizontalAlignment: Text.AlignRight }
                    }
                }

                // Invoice list
                ListView {
                    id: invoiceList
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true
                    spacing: 4
                    model: posBackend ? posBackend.recentInvoices : []

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: invoiceList.width
                        height: 48
                        radius: NeonStyle.radiusS
                        color: rowHov.containsMouse ? NeonStyle.surfaceLightColor : NeonStyle.surfaceColor
                        border.color: NeonStyle.borderColor
                        border.width: 1
                        Behavior on color { ColorAnimation { duration: 80 } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 16
                            spacing: 0

                            Text {
                                text: modelData.created_at || "—"
                                color: NeonStyle.textMuted
                                font.pixelSize: 13
                                Layout.preferredWidth: 160
                            }

                            Text {
                                text: modelData.iid || "—"
                                color: NeonStyle.textColor
                                font.pixelSize: 13
                                font.bold: true
                                font.family: "Courier New"
                                Layout.fillWidth: true
                                elide: Text.ElideRight
                            }

                            Text {
                                text: Number(modelData.tax  || 0).toFixed(3)
                                color: NeonStyle.textMuted
                                font.pixelSize: 13
                                Layout.preferredWidth: 110
                                horizontalAlignment: Text.AlignRight
                            }

                            Text {
                                text: Number(modelData.total || 0).toFixed(3) + " TND"
                                color: NeonStyle.primaryColor
                                font.pixelSize: 14
                                font.bold: true
                                Layout.preferredWidth: 130
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        MouseArea { id: rowHov; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }
                    }

                    // Empty state
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: invoiceList.count === 0
                        Text { Layout.alignment: Qt.AlignHCenter; text: "🧾"; font.pixelSize: 40; opacity: 0.3 }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "No transactions yet"; color: NeonStyle.textMuted; font.pixelSize: 15 }
                        Text { Layout.alignment: Qt.AlignHCenter; text: "Complete a sale to see it here"; color: NeonStyle.textMuted; font.pixelSize: 12 }
                    }
                }
            }
        }
    }

    // Named text references for live-update Connections above
    property alias revText: _revText
    property alias txnText: _txnText
    property alias vatText: _vatText
    Text { id: _revText; visible: false }
    Text { id: _txnText; visible: false }
    Text { id: _vatText; visible: false }
}