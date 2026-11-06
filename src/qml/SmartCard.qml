import QtQuick
import QtQuick.Layouts

Rectangle {
    id: card
    property color badgeColor: "#007AFF"
    property string badgeIcon: "📅"
    property string titleText: "Hoy"
    property int countValue: 0
    property bool isSelected: false
    property bool isWide: false

    property color cardBg: root.cardBg
    property color cardBorderColor: root.cardBorder
    property color textColor: root.textPrimary
    property color textSubColor: root.textSecondary
    property color hoverColor: root.hoverBg

    signal clicked()

    radius: 10
    color: isSelected ? cardBg : (cardMouse.containsMouse ? hoverColor : cardBg)
    border.color: isSelected ? badgeColor : cardBorderColor
    border.width: isSelected ? 1.8 : 1

    MouseArea {
        id: cardMouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: card.clicked()
    }

    Item {
        anchors.fill: parent
        anchors.margins: 10

        // Icon Badge
        Rectangle {
            id: iconBadge
            anchors.left: parent.left
            anchors.top: isWide ? undefined : parent.top
            anchors.verticalCenter: isWide ? parent.verticalCenter : undefined
            width: 30
            height: 30
            radius: 15
            color: card.badgeColor

            Text {
                anchors.centerIn: parent
                text: card.badgeIcon
                font.pixelSize: 15
                color: "#FFFFFF"
            }
        }

        // Count Number
        Text {
            anchors.right: parent.right
            anchors.top: isWide ? undefined : parent.top
            anchors.verticalCenter: isWide ? parent.verticalCenter : undefined
            text: card.countValue.toString()
            font.pixelSize: 22
            font.weight: Font.Bold
            color: card.textColor
        }

        // Label
        Text {
            anchors.left: isWide ? iconBadge.right : parent.left
            anchors.leftMargin: isWide ? 10 : 0
            anchors.bottom: isWide ? undefined : parent.bottom
            anchors.verticalCenter: isWide ? parent.verticalCenter : undefined
            text: card.titleText
            font.pixelSize: 13
            font.weight: Font.DemiBold
            color: card.isSelected ? card.badgeColor : card.textSubColor
        }
    }
}
