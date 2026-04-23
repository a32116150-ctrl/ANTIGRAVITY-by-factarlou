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
                font.pixelSize: NeonStyle.fontHeader
                font.bold: true
            }
            Text {
                text: "Track your business growth and financial performance"
                color: NeonStyle.textSecondaryColor
                font.pixelSize: NeonStyle.fontBody
            }
        }

        RowLayout {
            spacing: NeonStyle.spaceM
            Layout.fillWidth: true
            
            NeonCard {
                Layout.fillWidth: true
                Layout.preferredHeight: 200
                glowColor: NeonStyle.greenGlow
                
                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: NeonStyle.spaceM
                    Text {
                        text: "TOTAL REVENUE"
                        color: NeonStyle.textSecondaryColor
                        font.pixelSize: NeonStyle.fontSubTitle
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: (backend.dailySummary.revenue || 0).toFixed(3) + " TND"
                        color: NeonStyle.greenColor
                        font.pixelSize: 48
                        font.bold: true
                        Layout.alignment: Qt.AlignHCenter
                    }
                    Text {
                        text: "Across " + (backend.dailySummary.count || 0) + " successful transactions"
                        color: NeonStyle.textMuted
                        font.pixelSize: NeonStyle.fontBody
                        Layout.alignment: Qt.AlignHCenter
                    }
                }
            }
        }

        NeonCard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            
            ColumnLayout {
                anchors.fill: parent
                spacing: NeonStyle.spaceM
                
                Text {
                    text: "AVAILABLE ACTIONS"
                    color: NeonStyle.textColor
                    font.pixelSize: NeonStyle.fontTitle
                    font.bold: true
                }
                
                RowLayout {
                    spacing: NeonStyle.spaceM
                    
                    NeonButton {
                        text: "GENERATE Z-REPORT"
                        mainColor: NeonStyle.cyanColor
                        btnHeight: 60
                        Layout.fillWidth: true
                        onClicked: {
                            if (backend) backend.print_z_report(backend.dailySummary)
                        }
                    }
                    
                    NeonButton {
                        text: "EXPORT TO PDF"
                        mainColor: NeonStyle.magentaColor
                        btnHeight: 60
                        Layout.fillWidth: true
                        primary: false
                    }
                }
                
                Item { Layout.fillHeight: true }
                
                Text {
                    text: "Reports are generated based on the current fiscal day."
                    color: NeonStyle.textMuted
                    font.pixelSize: NeonStyle.fontCaption
                    font.italic: true
                }
            }
        }
    }

    Component.onCompleted: {
        if (backend) backend.request_daily_summary()
    }
}