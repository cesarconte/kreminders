/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-FileCopyrightText: 2026 CachyOS UI contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import CachyOS.UI

Rectangle {
    id: card

    property color gradientStart: "#3494FA"
    property color gradientEnd: "#63B4FF"
    property string badgeIcon: "calendar"
    property string titleText: qsTr("Hoy")
    property int countValue: 0
    property bool showCount: true
    property bool isTodayCalendar: false
    property bool isSelected: false

    signal clicked()

    implicitHeight: 58
    radius: 11

    gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: card.gradientStart }
        GradientStop { position: 1.0; color: card.gradientEnd }
    }

    border.width: card.isSelected ? 2 : 1
    border.color: card.isSelected ? "#FFFFFF" : Qt.rgba(1, 1, 1, 0.28)

    scale: cardTap.pressed ? 0.97 : 1.0
    Behavior on scale {
        NumberAnimation { duration: CachyTheme.animFast; easing.type: Easing.OutCubic }
    }

    // Subtle specular selection / hover overlay
    Rectangle {
        anchors.fill: parent
        radius: card.radius
        color: cardTap.pressed
            ? Qt.rgba(0, 0, 0, 0.12)
            : (cardHover.hovered ? Qt.rgba(1, 1, 1, 0.12) : "transparent")
        border.width: card.isSelected ? 1 : 0
        border.color: Qt.rgba(1, 1, 1, 0.65)

        Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }
    }

    HoverHandler {
        id: cardHover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: cardTap
        onTapped: card.clicked()
    }

    Item {
        anchors.fill: parent
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        anchors.topMargin: 8
        anchors.bottomMargin: 8

        // Top-Left Icon (Today Calendar with Day Number OR CachyIcon)
        Item {
            id: topLeftIcon
            anchors.left: parent.left
            anchors.top: parent.top
            width: 21
            height: 20

            Rectangle {
                visible: card.isTodayCalendar
                anchors.centerIn: parent
                width: 19
                height: 19
                radius: 4
                color: Qt.rgba(1, 1, 1, 0.18)
                border.width: 1.4
                border.color: "#FFFFFF"
                clip: true

                Rectangle {
                    anchors.top: parent.top
                    anchors.left: parent.left
                    anchors.right: parent.right
                    height: 5
                    color: "#FFFFFF"
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 1.5
                    text: new Date().getDate().toString()
                    font.pixelSize: 9
                    font.weight: Font.Bold
                    color: "#FFFFFF"
                }
            }

            CachyIcon {
                visible: !card.isTodayCalendar
                anchors.centerIn: parent
                name: card.badgeIcon
                size: 18
                color: "#FFFFFF"
            }
        }

        // Top-Right Count Number
        Text {
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.topMargin: -2
            visible: card.showCount
            text: card.countValue.toString()
            font.pixelSize: 19
            font.weight: Font.Bold
            color: "#FFFFFF"
        }

        // Bottom-Left Title Label
        Text {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.bottom: parent.bottom
            text: card.titleText
            font.pixelSize: 12
            font.weight: Font.DemiBold
            color: "#FFFFFF"
            elide: Text.ElideRight
        }
    }
}
