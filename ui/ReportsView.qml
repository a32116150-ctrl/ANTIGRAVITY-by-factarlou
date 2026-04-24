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

        ColumnLayout {
            spacing: 0
            Text {
                text: "ANALYTICS & REPORTS"
                color: NeonStyle.textColor
                font.pixelSize: 28
                font.bold: true
            }
            Text {
                text: "Track your business growth and financial performance"
                color: NeonStyle.textSecondaryColor
                font.pixelSize: 14
            }
        }

        RowLayout {
            spacing: NeonStyle.spaceM
            Layout.fillWidth: true
            
            NeonCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                hasShadow: true
                padding: NeonStyle.spaceL
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: NeonStyle.spaceM
                    Text {
                        text: "TOTAL REVENUE"
                        color: NeonStyle.textSecondaryColor
                        font.pixelSize: 16
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: ((posBackend && posBackend.dailySummary) ? (posBackend.dailySummary.revenue || 0).toFixed(3) : "0.000") + " TND"
                        color: NeonStyle.greenColor
                        font.pixelSize: 48
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "Across " + ((posBackend && posBackend.dailySummary) ? (posBackend.dailySummary.count || 0) : "0") + " successful transactions"
                        color: NeonStyle.textMuted
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        NeonCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            hasShadow: true
            padding: NeonStyle.spaceL
            
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: parent.padding
                spacing: NeonStyle.spaceM
                
                Text {
                    text: "AVAILABLE ACTIONS"
                    color: NeonStyle.textColor
                    font.pixelSize: 20
                    font.bold: true
                }
                
                RowLayout {
                    spacing: NeonStyle.spaceM
                    
                    NeonButton {
                        text: "GENERATE Z-REPORT"
                        mainColor: NeonStyle.primaryColor
                        btnHeight: 60
                        Layout.fillWidth: true
                        onClicked: {
                            if (posBackend) posBackend.print_z_report(posBackend.dailySummary)
                        }
                    }
                    
                    NeonButton {
                        text: "EXPORT TO PDF"
                        primary: false
                        btnHeight: 60
                        Layout.fillWidth: true
                    }
                }
                
                Item { Layout.fillHeight: true }
                
                Text {
                    text: "Reports are generated based on the current fiscal day."
                    color: NeonStyle.textMuted
                    font.pixelSize: 12
                    font.italic: true
                }
            }
        }
    }

    Component.onCompleted: {
        if (posBackend) posBackend.request_daily_summary()
    }
}