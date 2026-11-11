/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-FileCopyrightText: 2026 CachyOS UI contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Layouts
import QtQuick.Window
import CachyOS.UI

CachyWindow {
    id: root

    title: qsTr("Recordatorios")
    width: 940
    height: 640
    minimumWidth: 780
    minimumHeight: 520
    showTrafficLights: true

    // =========================================================================
    // 1. HEADER CENTER: Reminders Title Pill
    // =========================================================================
    headerCenter: [
        Rectangle {
            anchors.centerIn: parent
            height: 26
            width: headerPillRow.implicitWidth + 24
            radius: 13
            color: CachyTheme.cardBackground
            border.width: 1
            border.color: CachyTheme.specularBorder

            RowLayout {
                id: headerPillRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "🗓️"
                    font.pixelSize: 13
                }

                Text {
                    text: qsTr("Recordatorios")
                    font.pixelSize: 13
                    font.weight: Font.DemiBold
                    color: CachyTheme.textPrimary
                }
            }
        }
    ]

    // =========================================================================
    // 2. HEADER ACTIONS: Quick Add Reminder Button (18px from right edge)
    // =========================================================================
    headerActions: [
        Row {
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter

            CachyButton {
                text: "＋ " + qsTr("Nuevo recordatorio")
                primary: true
                implicitHeight: 28
                onClicked: {
                    newReminderInput.forceActiveFocus();
                }
            }
        }
    ]

    // =========================================================================
    // 3. CLIENT CONTENT AREA (Sidebar + Tasks View in Split Layout)
    // =========================================================================
    contentData: [
        RowLayout {
            anchors.fill: parent
            spacing: 0

            // -----------------------------------------------------------------
            // LEFT SIDEBAR (Translucent Liquid Glass)
            // -----------------------------------------------------------------
            Item {
                Layout.fillHeight: true
                Layout.preferredWidth: 280
                Layout.minimumWidth: 240
                Layout.maximumWidth: 320

                // Sidebar Liquid Glass Backplate
                Rectangle {
                    anchors.fill: parent
                    color: CachyTheme.withAlpha(CachyTheme.windowBackground, CachyTheme.isDark ? 0.30 : 0.45)
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    // Search Bar (Liquid Glass Capsule)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 32
                        radius: CachyTheme.radiusSmall
                        color: searchInput.activeFocus ? CachyTheme.cardBackgroundHover : CachyTheme.cardBackground
                        border.color: searchInput.activeFocus ? CachyTheme.accentColor : CachyTheme.specularBorder
                        border.width: 1

                        Behavior on border.color { ColorAnimation { duration: CachyTheme.animFast } }
                        Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 6

                            Text {
                                text: "🔍"
                                font.pixelSize: 12
                                opacity: 0.7
                            }

                            TextInput {
                                id: searchInput
                                Layout.fillWidth: true
                                font.pixelSize: 13
                                color: CachyTheme.textPrimary
                                clip: true
                                onTextChanged: remindersManager.searchQuery = text

                                Text {
                                    text: qsTr("Buscar")
                                    color: CachyTheme.textSecondary
                                    visible: !searchInput.text && !searchInput.activeFocus
                                    font.pixelSize: 13
                                }
                            }

                            Text {
                                text: "✕"
                                font.pixelSize: 11
                                color: CachyTheme.textSecondary
                                visible: searchInput.text.length > 0
                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: searchInput.text = ""
                                }
                            }
                        }
                    }

                    // Smart Lists 2x2 Grid + Completed Wide Card
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 2
                        rowSpacing: 8
                        columnSpacing: 8

                        // 1. HOY
                        SmartCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            badgeColor: "#007AFF"
                            badgeIcon: "📅"
                            titleText: qsTr("Hoy")
                            countValue: remindersManager.todayCount
                            isSelected: remindersManager.currentFilter === "today"
                            onClicked: remindersManager.selectSmartList("today")
                        }

                        // 2. PROGRAMADOS
                        SmartCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            badgeColor: "#FF3B30"
                            badgeIcon: "⏰"
                            titleText: qsTr("Programados")
                            countValue: remindersManager.scheduledCount
                            isSelected: remindersManager.currentFilter === "scheduled"
                            onClicked: remindersManager.selectSmartList("scheduled")
                        }

                        // 3. TODOS
                        SmartCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            badgeColor: "#5856D6"
                            badgeIcon: "📥"
                            titleText: qsTr("Todos")
                            countValue: remindersManager.allCount
                            isSelected: remindersManager.currentFilter === "all"
                            onClicked: remindersManager.selectSmartList("all")
                        }

                        // 4. CON MARCA
                        SmartCard {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 64
                            badgeColor: "#FF9500"
                            badgeIcon: "🚩"
                            titleText: qsTr("Con marca")
                            countValue: remindersManager.flaggedCount
                            isSelected: remindersManager.currentFilter === "flagged"
                            onClicked: remindersManager.selectSmartList("flagged")
                        }

                        // 5. COMPLETADAS (Fila ancha)
                        SmartCard {
                            Layout.columnSpan: 2
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            badgeColor: "#34C759"
                            badgeIcon: "✓"
                            titleText: qsTr("Completadas")
                            countValue: remindersManager.completedCount
                            isSelected: remindersManager.currentFilter === "completed"
                            onClicked: remindersManager.selectSmartList("completed")
                            isWide: true
                        }
                    }

                    // Heading: Mis listas
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.topMargin: 8

                        Text {
                            text: qsTr("Mis listas")
                            font.bold: true
                            font.pixelSize: 12
                            color: CachyTheme.textSecondary
                        }
                        Item { Layout.fillWidth: true }
                    }

                    // Custom Lists ScrollView
                    QQC2.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ListView {
                            id: customListView
                            anchors.fill: parent
                            model: remindersManager.listsModel
                            spacing: 2

                            delegate: Rectangle {
                                required property var model
                                width: customListView.width
                                height: 38
                                radius: CachyTheme.radiusSmall
                                color: (remindersManager.currentFilter === model.id)
                                    ? CachyTheme.cardBackgroundHover
                                    : (listMouse.containsMouse ? CachyTheme.cardBackgroundHover : "transparent")
                                border.color: (remindersManager.currentFilter === model.id)
                                    ? CachyTheme.specularBorder
                                    : "transparent"
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }

                                MouseArea {
                                    id: listMouse
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.RightButton) {
                                            listContextMenu.popup()
                                        } else {
                                            remindersManager.selectCustomList(model.id)
                                        }
                                    }
                                }

                                QQC2.Menu {
                                    id: listContextMenu
                                    QQC2.MenuItem {
                                        text: qsTr("Eliminar lista")
                                        onTriggered: remindersManager.deleteList(model.id)
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 10
                                    spacing: 8

                                    // Colored circle badge
                                    Rectangle {
                                        width: 24
                                        height: 24
                                        radius: 12
                                        color: model.color

                                        Text {
                                            anchors.centerIn: parent
                                            text: "•"
                                            font.bold: true
                                            color: "#FFFFFF"
                                            font.pixelSize: 18
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: model.name
                                        font.pixelSize: 13
                                        font.weight: (remindersManager.currentFilter === model.id) ? Font.DemiBold : Font.Normal
                                        color: CachyTheme.textPrimary
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        text: model.count.toString()
                                        font.pixelSize: 12
                                        color: CachyTheme.textSecondary
                                    }
                                }
                            }
                        }
                    }

                    // Footer: Añadir lista
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 34
                        radius: CachyTheme.radiusSmall
                        color: addListHover.hovered ? CachyTheme.cardBackgroundHover : "transparent"
                        border.width: addListHover.hovered ? 1 : 0
                        border.color: CachyTheme.specularBorder

                        Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 8
                            spacing: 8

                            Text {
                                text: "＋"
                                font.bold: true
                                font.pixelSize: 15
                                color: CachyTheme.accentColor
                            }

                            Text {
                                text: qsTr("Añadir lista")
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                color: CachyTheme.accentColor
                            }

                            Item { Layout.fillWidth: true }
                        }

                        HoverHandler { id: addListHover }
                        TapHandler {
                            onTapped: newListDialog.open()
                        }
                    }
                }

                // Vertical Divider Line between Sidebar and Main Content
                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    width: 1
                    color: CachyTheme.specularBorder
                }
            }

            // -----------------------------------------------------------------
            // RIGHT MAIN CONTENT AREA (Tasks List & Quick Add)
            // -----------------------------------------------------------------
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: CachyTheme.marginWindow
                    spacing: 16

                    // Top Header (Title + Count)
                    RowLayout {
                        Layout.fillWidth: true

                        ColumnLayout {
                            spacing: 2
                            Text {
                                text: remindersManager.currentTitle
                                font.bold: true
                                font.pixelSize: 30
                                color: remindersManager.currentColor
                            }
                            Text {
                                text: qsTr("%1 recordatorios").arg(tasksListView.count)
                                font.pixelSize: 13
                                color: CachyTheme.textSecondary
                            }
                        }

                        Item { Layout.fillWidth: true }
                    }

                    // Tasks List View
                    QQC2.ScrollView {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        clip: true

                        ListView {
                            id: tasksListView
                            anchors.fill: parent
                            model: remindersManager.tasksModel
                            spacing: 6

                            // Empty State Placeholder
                            Text {
                                anchors.centerIn: parent
                                text: qsTr("No hay recordatorios")
                                font.pixelSize: 15
                                color: CachyTheme.textSecondary
                                visible: tasksListView.count === 0
                            }

                            delegate: Rectangle {
                                id: taskRow
                                required property var model
                                width: tasksListView.width
                                height: taskCol.implicitHeight + 16
                                radius: CachyTheme.radiusMedium
                                color: rowHover.hovered ? CachyTheme.cardBackgroundHover : "transparent"
                                border.color: rowHover.hovered ? CachyTheme.specularBorder : "transparent"
                                border.width: 1

                                Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }

                                HoverHandler { id: rowHover }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    // Circular Animated Checkbox
                                    Rectangle {
                                        width: 22
                                        height: 22
                                        radius: 11
                                        color: taskRow.model.isCompleted ? taskRow.model.listColor : "transparent"
                                        border.color: taskRow.model.isCompleted ? taskRow.model.listColor : CachyTheme.specularBorder
                                        border.width: 1.8

                                        Text {
                                            anchors.centerIn: parent
                                            text: "✓"
                                            font.bold: true
                                            font.pixelSize: 12
                                            color: "#FFFFFF"
                                            visible: taskRow.model.isCompleted
                                        }

                                        TapHandler {
                                            onTapped: remindersManager.toggleCompleted(taskRow.model.id)
                                        }
                                    }

                                    // Task Details (Title, Notes, DueDate)
                                    ColumnLayout {
                                        id: taskCol
                                        Layout.fillWidth: true
                                        spacing: 4

                                        Text {
                                            Layout.fillWidth: true
                                            text: taskRow.model.title
                                            font.pixelSize: 14
                                            font.strikeout: taskRow.model.isCompleted
                                            color: taskRow.model.isCompleted ? CachyTheme.textSecondary : CachyTheme.textPrimary
                                            elide: Text.ElideRight
                                        }

                                        Text {
                                            Layout.fillWidth: true
                                            text: taskRow.model.notes
                                            font.pixelSize: 12
                                            color: CachyTheme.textSecondary
                                            visible: taskRow.model.notes.length > 0
                                            elide: Text.ElideRight
                                        }

                                        RowLayout {
                                            spacing: 8
                                            visible: taskRow.model.hasDueDate || taskRow.model.isFlagged

                                            Text {
                                                text: "⏰ " + taskRow.model.dueDateStr
                                                font.pixelSize: 11
                                                color: taskRow.model.isOverdue ? "#FF3B30" : CachyTheme.textSecondary
                                                visible: taskRow.model.hasDueDate
                                            }

                                            Text {
                                                text: "🚩"
                                                font.pixelSize: 11
                                                visible: taskRow.model.isFlagged
                                            }

                                            // Badge of List Name if in Smart List
                                            Rectangle {
                                                visible: remindersManager.currentFilter !== taskRow.model.listId
                                                height: 16
                                                width: listBadgeText.implicitWidth + 8
                                                radius: 4
                                                color: taskRow.model.listColor
                                                opacity: CachyTheme.isDark ? 0.25 : 0.15
                                            }
                                            Text {
                                                id: listBadgeText
                                                visible: remindersManager.currentFilter !== taskRow.model.listId
                                                text: taskRow.model.listName
                                                font.pixelSize: 10
                                                color: taskRow.model.listColor
                                                font.weight: Font.DemiBold
                                            }
                                        }
                                    }

                                    // Actions (Hover buttons: Flag, Delete)
                                    RowLayout {
                                        spacing: 6
                                        visible: rowHover.hovered

                                        Rectangle {
                                            width: 24
                                            height: 24
                                            radius: 12
                                            color: flagHover.hovered ? CachyTheme.cardBackgroundHover : "transparent"
                                            Text {
                                                anchors.centerIn: parent
                                                text: taskRow.model.isFlagged ? "🚩" : "🏳️"
                                                font.pixelSize: 13
                                            }
                                            HoverHandler { id: flagHover }
                                            TapHandler {
                                                onTapped: remindersManager.toggleFlagged(taskRow.model.id)
                                            }
                                        }

                                        Rectangle {
                                            width: 24
                                            height: 24
                                            radius: 12
                                            color: delHover.hovered ? CachyTheme.cardBackgroundHover : "transparent"
                                            Text {
                                                anchors.centerIn: parent
                                                text: "🗑️"
                                                font.pixelSize: 13
                                            }
                                            HoverHandler { id: delHover }
                                            TapHandler {
                                                onTapped: remindersManager.deleteReminder(taskRow.model.id)
                                            }
                                        }
                                    }
                                }

                                // Bottom subtle separator line
                                Rectangle {
                                    anchors.bottom: parent.bottom
                                    anchors.left: parent.left
                                    anchors.leftMargin: 44
                                    anchors.right: parent.right
                                    height: 1
                                    color: CachyTheme.specularBorder
                                }
                            }
                        }
                    }

                    // Bottom Quick Add Input (Liquid Glass Card)
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 46
                        radius: CachyTheme.radiusMedium
                        color: newReminderInput.activeFocus ? CachyTheme.cardBackgroundHover : CachyTheme.cardBackground
                        border.color: newReminderInput.activeFocus ? CachyTheme.accentColor : CachyTheme.specularBorder
                        border.width: 1

                        Behavior on border.color { ColorAnimation { duration: CachyTheme.animFast } }
                        Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 8
                            spacing: 10

                            Text {
                                text: "＋"
                                font.bold: true
                                font.pixelSize: 18
                                color: remindersManager.currentColor
                            }

                            TextInput {
                                id: newReminderInput
                                Layout.fillWidth: true
                                font.pixelSize: 14
                                color: CachyTheme.textPrimary
                                clip: true
                                onAccepted: {
                                    if (text.trim().length > 0) {
                                        remindersManager.addReminder(text.trim(), "", new Date(), false, false, 0);
                                        text = "";
                                    }
                                }

                                Text {
                                    text: qsTr("Nuevo recordatorio (presiona Enter para guardar)")
                                    color: CachyTheme.textSecondary
                                    visible: !newReminderInput.text && !newReminderInput.activeFocus
                                    font.pixelSize: 14
                                }
                            }

                            CachyButton {
                                text: qsTr("Añadir")
                                primary: true
                                enabled: newReminderInput.text.trim().length > 0
                                implicitHeight: 32
                                onClicked: {
                                    if (newReminderInput.text.trim().length > 0) {
                                        remindersManager.addReminder(newReminderInput.text.trim(), "", new Date(), false, false, 0);
                                        newReminderInput.text = "";
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },

        // =====================================================================
        // NEW LIST MODAL DIALOG
        // =====================================================================
        QQC2.Dialog {
            id: newListDialog
            title: qsTr("Nueva lista")
            standardButtons: QQC2.Dialog.Ok | QQC2.Dialog.Cancel
            anchors.centerIn: parent
            width: 340
            modal: true

            property string selectedColor: "#007AFF"

            background: Rectangle {
                radius: CachyTheme.radiusLarge
                color: CachyTheme.isDark ? Qt.rgba(0.12, 0.12, 0.15, 0.95) : Qt.rgba(0.96, 0.97, 1.0, 0.95)
                border.width: 1
                border.color: CachyTheme.specularBorder
            }

            ColumnLayout {
                spacing: 12
                width: parent.width

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 34
                    radius: CachyTheme.radiusSmall
                    color: CachyTheme.cardBackground
                    border.width: 1
                    border.color: CachyTheme.specularBorder

                    TextInput {
                        id: listNameInput
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        verticalAlignment: TextInput.AlignVCenter
                        color: CachyTheme.textPrimary
                        font.pixelSize: 13
                        focus: true

                        Text {
                            text: qsTr("Nombre de la lista")
                            color: CachyTheme.textSecondary
                            visible: !listNameInput.text && !listNameInput.activeFocus
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: 13
                        }
                    }
                }

                Text {
                    text: qsTr("Color de la lista:")
                    font.pixelSize: 12
                    color: CachyTheme.textSecondary
                }

                RowLayout {
                    spacing: 8
                    Repeater {
                        model: ["#007AFF", "#FF9500", "#FF3B30", "#34C759", "#AF52DE", "#5856D6", "#FF2D55", "#5AC8FA"]
                        Rectangle {
                            required property var modelData
                            width: 26
                            height: 26
                            radius: 13
                            color: modelData
                            border.color: (newListDialog.selectedColor === modelData) ? (CachyTheme.isDark ? "#FFFFFF" : "#1C1C1E") : "transparent"
                            border.width: 2.5

                            TapHandler {
                                onTapped: newListDialog.selectedColor = parent.modelData
                            }
                        }
                    }
                }
            }

            onAccepted: {
                if (listNameInput.text.trim().length > 0) {
                    remindersManager.addList(listNameInput.text.trim(), selectedColor, "list");
                    listNameInput.text = "";
                }
            }
        }
    ]
}
