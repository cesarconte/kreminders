import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

ApplicationWindow {
    id: root
    visible: true
    width: 920
    height: 620
    minimumWidth: 760
    minimumHeight: 500
    title: qsTr("Recordatorios")

    // Dynamic Theme Integration with KDE Plasma (Breeze / BreezeDark)
    readonly property bool isDark: remindersManager.isDark
    readonly property color highlightColor: remindersManager.highlightColor

    readonly property color sidebarBg: isDark ? "#202326" : "#EBEBF0"
    readonly property color contentBg: isDark ? "#141618" : "#FFFFFF"
    readonly property color cardBg: isDark ? "#2A2E32" : "#FFFFFF"
    readonly property color cardBorder: isDark ? "#373B3F" : "#E0E0E5"
    readonly property color inputBg: isDark ? "#2A2E32" : "#FFFFFF"
    readonly property color quickAddBg: isDark ? "#202326" : "#F5F5F7"
    readonly property color textPrimary: isDark ? "#FCFCFC" : "#1C1C1E"
    readonly property color textSecondary: isDark ? "#9DA3A8" : "#8E8E93"
    readonly property color dividerColor: isDark ? "#31363B" : "#D1D1D6"
    readonly property color selectionBg: isDark ? "#2C343D" : "#D6D6DC"
    readonly property color hoverBg: isDark ? "#272A2E" : "#E0E0E6"

    color: root.sidebarBg

    RowLayout {
        anchors.fill: parent
        spacing: 0

        // =====================================================================
        // LEFT SIDEBAR
        // =====================================================================
        Rectangle {
            Layout.fillHeight: true
            Layout.preferredWidth: 280
            Layout.minimumWidth: 240
            Layout.maximumWidth: 320
            color: root.sidebarBg

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                // Search Bar
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    radius: 8
                    color: root.inputBg
                    border.color: root.cardBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 8
                        anchors.rightMargin: 8
                        spacing: 6

                        Text {
                            text: "🔍"
                            font.pixelSize: 12
                            color: root.textSecondary
                            opacity: 0.7
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            font.pixelSize: 13
                            color: root.textPrimary
                            clip: true
                            onTextChanged: remindersManager.searchQuery = text

                            Text {
                                text: qsTr("Buscar")
                                color: root.textSecondary
                                visible: !searchInput.text && !searchInput.activeFocus
                                font.pixelSize: 13
                            }
                        }

                        Text {
                            text: "✕"
                            font.pixelSize: 11
                            color: root.textSecondary
                            visible: searchInput.text.length > 0
                            MouseArea {
                                anchors.fill: parent
                                onClicked: searchInput.text = ""
                            }
                        }
                    }
                }

                // Smart Lists 2x2 Grid + Completed
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

                    // 5. COMPLETADAS (Fila completa)
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
                        color: root.textSecondary
                    }
                    Item { Layout.fillWidth: true }
                }

                // Custom Lists ScrollView
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        id: customListView
                        anchors.fill: parent
                        model: remindersManager.listsModel
                        spacing: 2

                        delegate: Rectangle {
                            width: customListView.width
                            height: 38
                            radius: 8
                            color: (remindersManager.currentFilter === model.id) ? root.selectionBg : (listMouse.containsMouse ? root.hoverBg : "transparent")

                            MouseArea {
                                id: listMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: (mouse) => {
                                    if (mouse.button === Qt.RightButton) {
                                        listContextMenu.popup()
                                    } else {
                                        remindersManager.selectCustomList(model.id)
                                    }
                                }
                            }

                            Menu {
                                id: listContextMenu
                                MenuItem {
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
                                    color: root.textPrimary
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: model.count.toString()
                                    font.pixelSize: 12
                                    color: root.textSecondary
                                }
                            }
                        }
                    }
                }

                // Footer: Añadir lista
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 32
                    color: "transparent"

                    RowLayout {
                        anchors.fill: parent
                        spacing: 6

                        Text {
                            text: "＋"
                            font.bold: true
                            font.pixelSize: 15
                            color: root.highlightColor
                        }

                        Text {
                            text: qsTr("Añadir lista")
                            font.pixelSize: 13
                            font.weight: Font.DemiBold
                            color: root.highlightColor
                        }

                        Item { Layout.fillWidth: true }
                    }

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: newListDialog.open()
                    }
                }
            }

            // Divider vertical
            Rectangle {
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: 1
                color: root.dividerColor
            }
        }

        // =====================================================================
        // RIGHT MAIN CONTENT AREA
        // =====================================================================
        Rectangle {
            Layout.fillWidth: true
            Layout.fillHeight: true
            color: root.contentBg

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
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
                            color: root.textSecondary
                        }
                    }

                    Item { Layout.fillWidth: true }
                }

                // Tasks List View
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        id: tasksListView
                        anchors.fill: parent
                        model: remindersManager.tasksModel
                        spacing: 8

                        // Empty State Placeholder
                        Text {
                            anchors.centerIn: parent
                            text: qsTr("No hay recordatorios")
                            font.pixelSize: 16
                            color: root.textSecondary
                            visible: tasksListView.count === 0
                        }

                        delegate: Rectangle {
                            id: taskRow
                            width: tasksListView.width
                            height: taskCol.implicitHeight + 16
                            radius: 10
                            color: rowMouse.containsMouse ? root.hoverBg : "transparent"
                            border.color: rowMouse.containsMouse ? root.cardBorder : "transparent"
                            border.width: 1

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 12
                                spacing: 12

                                // Circular Animated Checkbox
                                Rectangle {
                                    width: 22
                                    height: 22
                                    radius: 11
                                    color: model.isCompleted ? model.listColor : "transparent"
                                    border.color: model.isCompleted ? model.listColor : (root.isDark ? "#5C6166" : "#C7C7CC")
                                    border.width: 1.8

                                    Text {
                                        anchors.centerIn: parent
                                        text: "✓"
                                        font.bold: true
                                        font.pixelSize: 12
                                        color: "#FFFFFF"
                                        visible: model.isCompleted
                                    }

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: remindersManager.toggleCompleted(model.id)
                                    }
                                }

                                // Task Details (Title, Notes, DueDate)
                                ColumnLayout {
                                    id: taskCol
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        Layout.fillWidth: true
                                        text: model.title
                                        font.pixelSize: 14
                                        font.strikeout: model.isCompleted
                                        color: model.isCompleted ? root.textSecondary : root.textPrimary
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: model.notes
                                        font.pixelSize: 12
                                        color: root.textSecondary
                                        visible: model.notes.length > 0
                                        elide: Text.ElideRight
                                    }

                                    RowLayout {
                                        spacing: 8
                                        visible: model.hasDueDate || model.isFlagged

                                        Text {
                                            text: "⏰ " + model.dueDateStr
                                            font.pixelSize: 11
                                            color: model.isOverdue ? "#FF3B30" : root.textSecondary
                                            visible: model.hasDueDate
                                        }

                                        Text {
                                            text: "🚩"
                                            font.pixelSize: 11
                                            visible: model.isFlagged
                                        }

                                        // Badge of List Name if in Smart List
                                        Rectangle {
                                            visible: remindersManager.currentFilter !== model.listId
                                            height: 16
                                            width: listBadgeText.implicitWidth + 8
                                            radius: 4
                                            color: model.listColor
                                            opacity: root.isDark ? 0.25 : 0.15
                                        }
                                        Text {
                                            id: listBadgeText
                                            visible: remindersManager.currentFilter !== model.listId
                                            text: model.listName
                                            font.pixelSize: 10
                                            color: model.listColor
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }

                                // Actions (Hover buttons: Flag, Delete)
                                RowLayout {
                                    spacing: 4
                                    visible: rowMouse.containsMouse

                                    Text {
                                        text: model.isFlagged ? "🚩" : "🏳️"
                                        font.pixelSize: 13
                                        opacity: 0.8
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: remindersManager.toggleFlagged(model.id)
                                        }
                                    }

                                    Text {
                                        text: "🗑️"
                                        font.pixelSize: 13
                                        opacity: 0.7
                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: remindersManager.deleteReminder(model.id)
                                        }
                                    }
                                }
                            }

                            // Bottom subtle separator line
                            Rectangle {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.leftMargin: 42
                                anchors.right: parent.right
                                height: 0.8
                                color: root.dividerColor
                            }
                        }
                    }
                }

                // Bottom Quick Add Input
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 46
                    radius: 10
                    color: root.quickAddBg
                    border.color: root.cardBorder
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
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
                            color: root.textPrimary
                            clip: true
                            onAccepted: {
                                if (text.trim().length > 0) {
                                    remindersManager.addReminder(text.trim(), "", new Date(), false, false, 0)
                                    text = ""
                                }
                            }

                            Text {
                                text: qsTr("Nuevo recordatorio (presiona Enter para guardar)")
                                color: root.textSecondary
                                visible: !newReminderInput.text && !newReminderInput.activeFocus
                                font.pixelSize: 14
                            }
                        }

                        Button {
                            id: addBtn
                            text: qsTr("Añadir")
                            enabled: newReminderInput.text.trim().length > 0
                            font.pixelSize: 13
                            font.weight: Font.DemiBold

                            contentItem: Text {
                                text: addBtn.text
                                font: addBtn.font
                                opacity: addBtn.enabled ? 1.0 : 0.6
                                color: addBtn.enabled ? "#FFFFFF" : (root.isDark ? "#7A8086" : "#8E8E93")
                                horizontalAlignment: Text.AlignHCenter
                                verticalAlignment: Text.AlignVCenter
                            }

                            background: Rectangle {
                                implicitWidth: 74
                                implicitHeight: 30
                                radius: 6
                                color: {
                                    if (!addBtn.enabled) {
                                        return root.isDark ? "#2C3034" : "#E2E2E6";
                                    }
                                    if (addBtn.down) {
                                        return Qt.darker(remindersManager.currentColor, 1.2);
                                    }
                                    if (addBtn.hovered) {
                                        return Qt.lighter(remindersManager.currentColor, 1.1);
                                    }
                                    return remindersManager.currentColor;
                                }
                                border.color: addBtn.enabled ? Qt.darker(remindersManager.currentColor, 1.15) : "transparent"
                                border.width: addBtn.enabled ? 1 : 0
                            }

                            onClicked: {
                                if (newReminderInput.text.trim().length > 0) {
                                    remindersManager.addReminder(newReminderInput.text.trim(), "", new Date(), false, false, 0)
                                    newReminderInput.text = ""
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // NEW LIST DIALOG
    // =========================================================================
    Dialog {
        id: newListDialog
        title: qsTr("Nueva lista")
        standardButtons: Dialog.Ok | Dialog.Cancel
        anchors.centerIn: parent
        width: 340
        modal: true

        property string selectedColor: "#007AFF"

        ColumnLayout {
            spacing: 12
            width: parent.width

            TextField {
                id: listNameInput
                Layout.fillWidth: true
                placeholderText: qsTr("Nombre de la lista")
                focus: true
            }

            Text {
                text: qsTr("Color de la lista:")
                font.pixelSize: 12
                color: root.textSecondary
            }

            RowLayout {
                spacing: 8
                Repeater {
                    model: ["#007AFF", "#FF9500", "#FF3B30", "#34C759", "#AF52DE", "#5856D6", "#FF2D55", "#5AC8FA"]
                    Rectangle {
                        width: 26
                        height: 26
                        radius: 13
                        color: modelData
                        border.color: (newListDialog.selectedColor === modelData) ? (root.isDark ? "#FFFFFF" : "#1C1C1E") : "transparent"
                        border.width: 2.5

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: newListDialog.selectedColor = modelData
                        }
                    }
                }
            }
        }

        onAccepted: {
            if (listNameInput.text.trim().length > 0) {
                remindersManager.addList(listNameInput.text.trim(), selectedColor, "list")
                listNameInput.text = ""
            }
        }
    }
}
