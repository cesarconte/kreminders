import QtQuick
import QtQuick.Layouts
import CachyOS.UI

Rectangle {
    id: card
    property color badgeColor: "#007AFF"
    property string badgeIcon: "📅"
    property string titleText: "Hoy"
    property int countValue: 0
    property bool isSelected: false
    property bool isWide: false

    signal clicked()

    radius: CachyTheme.radiusMedium
    color: isSelected
        ? CachyTheme.withAlpha(badgeColor, 0.14)
        : (cardMouse.containsMouse ? CachyTheme.cardBackgroundHover : CachyTheme.cardBackground)
    border.color: isSelected ? badgeColor : (cardMouse.containsMouse ? CachyTheme.withAlpha(badgeColor, 0.5) : CachyTheme.specularBorder)
    border.width: isSelected ? 1.5 : 1

    Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }
    Behavior on border.color { ColorAnimation { duration: CachyTheme.animFast } }

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

            CachyIcon {
                id: cachyBadgeIcon
                anchors.centerIn: parent
                name: card.badgeIcon
                size: 16
                color: "#FFFFFF"
                visible: card.badgeIcon.indexOf("/") === -1 && card.badgeIcon.length > 2 && !card.badgeIcon.match(/[\u{1F300}-\u{1F6FF}]/u)
            }

            Text {
                anchors.centerIn: parent
                text: card.badgeIcon
                font.pixelSize: 15
                color: "#FFFFFF"
                visible: !cachyBadgeIcon.visible
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
            color: CachyTheme.textPrimary
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
            color: card.isSelected ? card.badgeColor : CachyTheme.textSecondary
        }
    }
}
