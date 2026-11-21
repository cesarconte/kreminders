/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-FileCopyrightText: 2026 CachyOS UI contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls as QQC2
import QtQuick.Effects
import QtQuick.Layouts
import QtQuick.Window
import CachyOS.UI

CachyWindow {
    id: root

    title: qsTr("Recordatorios")
    width: 960
    height: 640
    minimumWidth: 780
    minimumHeight: 520
    showTrafficLights: true
    showTitle: false
    showTitleBarDivider: false
    sidebarWidthExpanded: 276

    // =========================================================================
    // INLINE DRAFT, SUGGESTION & SHORTCUT STATE (macOS Golden Gate UX)
    // =========================================================================
    property bool isDraftActive: false
    property bool groceriesSuggestionDismissed: false
    signal draftRequested()

    function startInlineDraft() {
        root.isDraftActive = true;
        tasksListView.positionViewAtEnd();
        draftRequested();
    }

    Shortcut {
        sequences: [StandardKey.New]
        onActivated: root.startInlineDraft()
    }

    // =========================================================================
    // 1. SIDEBAR TOP BAR ACTIONS (Add List + Sidebar Toggle)
    // =========================================================================
    sidebarHeaderActions: [
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Add List Button (Golden Gate Liquid Glass Circle)
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: addListTopTap.pressed
                    ? CachyPalette.pressedOverlay
                    : (addListTopHover.hovered ? CachyPalette.cardBackgroundHover : CachyPalette.surfacePill)
                border.width: 1
                border.color: CachyPalette.specularBorder

                Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }

                Item {
                    anchors.centerIn: parent
                    width: 16
                    height: 16

                    CachyIcon {
                        anchors.centerIn: parent
                        name: "list"
                        size: 14
                        color: CachyPalette.text
                    }

                    Rectangle {
                        anchors.right: parent.right
                        anchors.bottom: parent.bottom
                        anchors.rightMargin: -2
                        anchors.bottomMargin: -1
                        width: 8
                        height: 8
                        radius: 4
                        color: CachyTheme.accentColor

                        Text {
                            anchors.centerIn: parent
                            text: "+"
                            font.pixelSize: 8
                            font.bold: true
                            color: "#FFFFFF"
                        }
                    }
                }

                HoverHandler {
                    id: addListTopHover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    id: addListTopTap
                    onTapped: newListDialog.openDialog()
                }
                QQC2.ToolTip.visible: addListTopHover.hovered
                QQC2.ToolTip.text: qsTr("Añadir lista")
                QQC2.ToolTip.delay: 450
            }

            // Toggle Sidebar Button (Golden Gate Liquid Glass Circle)
            Rectangle {
                width: 28
                height: 28
                radius: 14
                color: toggleSideTap.pressed
                    ? CachyPalette.pressedOverlay
                    : (toggleSideHover.hovered ? CachyPalette.cardBackgroundHover : CachyPalette.surfacePill)
                border.width: 1
                border.color: CachyPalette.specularBorder

                Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }

                CachyIcon {
                    anchors.centerIn: parent
                    name: "sidebar"
                    size: 14
                    color: CachyPalette.text
                }

                HoverHandler {
                    id: toggleSideHover
                    cursorShape: Qt.PointingHandCursor
                }
                TapHandler {
                    id: toggleSideTap
                    onTapped: root.toggleSidebar()
                }
                QQC2.ToolTip.visible: toggleSideHover.hovered
                QQC2.ToolTip.text: qsTr("Ocultar barra lateral")
                QQC2.ToolTip.delay: 450
            }
        }
    ]

    // =========================================================================
    // 2. RIGHT PANE TOOLBAR LEADING (Re-open Sidebar when hidden)
    // =========================================================================
    headerLeading: [
        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            visible: !root.sidebarVisible
            width: visible ? 28 : 0
            height: 28
            radius: 14
            color: showSideTap.pressed
                ? CachyPalette.pressedOverlay
                : (showSideHover.hovered ? CachyPalette.cardBackgroundHover : CachyPalette.surfacePill)
            border.width: 1
            border.color: CachyPalette.specularBorder

            CachyIcon {
                anchors.centerIn: parent
                name: "sidebar"
                size: 14
                color: CachyPalette.text
            }

            HoverHandler {
                id: showSideHover
                cursorShape: Qt.PointingHandCursor
            }
            TapHandler {
                id: showSideTap
                onTapped: root.toggleSidebar()
            }
            QQC2.ToolTip.visible: showSideHover.hovered
            QQC2.ToolTip.text: qsTr("Mostrar barra lateral")
            QQC2.ToolTip.delay: 450
        }
    ]

    // =========================================================================
    // 3. RIGHT PANE TOOLBAR ACTIONS (Grouped 3-Action Pill + Search Capsule)
    // =========================================================================
    headerActions: [
        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: 8

            // Grouped 3-Action Capsule (Share | Sort/List Options | Add Reminder)
            Rectangle {
                height: 28
                width: actionPillRow.implicitWidth + 8
                radius: 14
                color: CachyPalette.surfacePill
                border.width: 1
                border.color: CachyPalette.specularBorder

                Row {
                    id: actionPillRow
                    anchors.centerIn: parent
                    spacing: 2

                    // Share Button
                    Rectangle {
                        width: 26
                        height: 22
                        radius: 11
                        color: shareTap.pressed
                            ? CachyPalette.pressedOverlay
                            : (shareHover.hovered ? CachyPalette.hoverOverlay : "transparent")

                        CachyIcon {
                            anchors.centerIn: parent
                            name: "share"
                            size: 14
                            color: CachyPalette.text
                        }

                        HoverHandler {
                            id: shareHover
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            id: shareTap
                            onTapped: {
                                remindersManager.copyCurrentListToClipboard();
                                statusToast.show(qsTr("Lista copiada al portapapeles"), "success", 2000);
                            }
                        }
                        QQC2.ToolTip.visible: shareHover.hovered
                        QQC2.ToolTip.text: qsTr("Compartir / Copiar lista")
                        QQC2.ToolTip.delay: 450
                    }

                    // Sort / View Options Button
                    Rectangle {
                        id: sortMenuAnchor
                        width: 26
                        height: 22
                        radius: 11
                        color: sortTap.pressed
                            ? CachyPalette.pressedOverlay
                            : (sortHover.hovered ? CachyPalette.hoverOverlay : "transparent")

                        CachyIcon {
                            anchors.centerIn: parent
                            name: "list"
                            size: 14
                            color: CachyPalette.text
                        }

                        HoverHandler {
                            id: sortHover
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            id: sortTap
                            onTapped: sortMenu.popup(sortMenuAnchor, 0, sortMenuAnchor.height + 6)
                        }
                        QQC2.ToolTip.visible: sortHover.hovered
                        QQC2.ToolTip.text: qsTr("Ordenar y opciones")
                        QQC2.ToolTip.delay: 450

                        CachyMenu {
                            id: sortMenu

                            CachyMenuItem {
                                text: qsTr("Ordenar por fecha")
                                checkable: true
                                checked: remindersManager.sortBy === "manual"
                                onTriggered: remindersManager.sortBy = "manual"
                            }
                            CachyMenuItem {
                                text: qsTr("Ordenar por creación")
                                checkable: true
                                checked: remindersManager.sortBy === "creationDate"
                                onTriggered: remindersManager.sortBy = "creationDate"
                            }
                            CachyMenuItem {
                                text: qsTr("Ordenar por prioridad")
                                checkable: true
                                checked: remindersManager.sortBy === "priority"
                                onTriggered: remindersManager.sortBy = "priority"
                            }
                            CachyMenuItem {
                                text: qsTr("Ordenar por título")
                                checkable: true
                                checked: remindersManager.sortBy === "title"
                                onTriggered: remindersManager.sortBy = "title"
                            }
                            CachyMenuSeparator {}
                            CachyMenuItem {
                                text: remindersManager.showCompleted ? qsTr("Ocultar completados") : qsTr("Mostrar completados")
                                checkable: true
                                checked: remindersManager.showCompleted
                                onTriggered: remindersManager.showCompleted = !remindersManager.showCompleted
                            }
                        }
                    }

                    // Add Reminder (+) Button
                    Rectangle {
                        width: 26
                        height: 22
                        radius: 11
                        color: addRemTap.pressed
                            ? CachyPalette.pressedOverlay
                            : (addRemHover.hovered ? CachyPalette.hoverOverlay : "transparent")

                        CachyIcon {
                            anchors.centerIn: parent
                            name: "add"
                            size: 14
                            color: CachyPalette.text
                        }

                        HoverHandler {
                            id: addRemHover
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            id: addRemTap
                            onTapped: root.startInlineDraft()
                        }
                        QQC2.ToolTip.visible: addRemHover.hovered
                        QQC2.ToolTip.text: qsTr("Nuevo recordatorio (Ctrl+N)")
                        QQC2.ToolTip.delay: 450
                    }
                }
            }

            // Search Capsule (macOS Golden Gate Top-Right Search)
            Rectangle {
                width: 192
                height: 28
                radius: 14
                color: searchInput.activeFocus ? CachyPalette.cardBackgroundHover : CachyPalette.surfacePill
                border.width: searchInput.activeFocus ? 1.5 : 1
                border.color: searchInput.activeFocus ? CachyTheme.accentColor : CachyPalette.specularBorder

                Behavior on border.color { ColorAnimation { duration: CachyTheme.animFast } }
                Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 8
                    spacing: 6

                    CachyIcon {
                        name: "search"
                        size: 13
                        color: CachyPalette.textSecondary
                    }

                    TextInput {
                        id: searchInput
                        Layout.fillWidth: true
                        font.pixelSize: 13
                        color: CachyPalette.text
                        clip: true
                        verticalAlignment: TextInput.AlignVCenter
                        onTextChanged: remindersManager.searchQuery = text

                        Keys.onEscapePressed: {
                            text = "";
                            focus = false;
                        }

                        Text {
                            text: qsTr("Buscar")
                            color: CachyPalette.textSecondary
                            visible: !searchInput.text && !searchInput.activeFocus
                            font.pixelSize: 13
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 15
                        Layout.preferredHeight: 15
                        radius: 7.5
                        visible: searchInput.text.length > 0
                        color: clearSearchHover.hovered ? CachyPalette.pressedOverlay : CachyPalette.hoverOverlay

                        CachyIcon {
                            anchors.centerIn: parent
                            name: "close"
                            size: 9
                            color: CachyPalette.textSecondary
                        }

                        HoverHandler {
                            id: clearSearchHover
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            onTapped: searchInput.text = ""
                        }
                    }
                }
            }
        }
    ]

    // =========================================================================
    // 4. EDGE-TO-EDGE LIQUID GLASS SIDEBAR (2x3 Smart Cards, Lists & Tags)
    // =========================================================================
    sidebar: [
        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.topMargin: 6
            anchors.bottomMargin: 12
            spacing: 12

            // 2x3 Smart Lists Grid
            GridLayout {
                Layout.fillWidth: true
                columns: 2
                rowSpacing: 8
                columnSpacing: 8

                // 1. HOY
                SmartCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 58
                    gradientStart: "#3494FA"
                    gradientEnd: "#63B4FF"
                    isTodayCalendar: true
                    titleText: qsTr("Hoy")
                    countValue: remindersManager.todayCount
                    isSelected: remindersManager.currentFilter === "today"
                    onClicked: remindersManager.selectSmartList("today")
                }

                // 2. PROGRAMADOS
                SmartCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 58
                    gradientStart: "#E85755"
                    gradientEnd: "#F3837F"
                    badgeIcon: "calendar"
                    titleText: qsTr("Programados")
                    countValue: remindersManager.scheduledCount
                    isSelected: remindersManager.currentFilter === "scheduled"
                    onClicked: remindersManager.selectSmartList("scheduled")
                }

                // 3. TODOS
                SmartCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 58
                    gradientStart: "#3E4044"
                    gradientEnd: "#63666C"
                    badgeIcon: "inbox"
                    titleText: qsTr("Todos")
                    countValue: remindersManager.allCount
                    isSelected: remindersManager.currentFilter === "all"
                    onClicked: remindersManager.selectSmartList("all")
                }

                // 4. CON MARCA
                SmartCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 58
                    gradientStart: "#EE964B"
                    gradientEnd: "#F6BC7C"
                    badgeIcon: "flag"
                    titleText: qsTr("Con marca")
                    countValue: remindersManager.flaggedCount
                    isSelected: remindersManager.currentFilter === "flagged"
                    onClicked: remindersManager.selectSmartList("flagged")
                }

                // 5. URGENTES
                SmartCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 58
                    gradientStart: "#E55882"
                    gradientEnd: "#F088A7"
                    badgeIcon: "alarm"
                    titleText: qsTr("Urgentes")
                    countValue: remindersManager.urgentCount
                    isSelected: remindersManager.currentFilter === "urgent"
                    onClicked: remindersManager.selectSmartList("urgent")
                }

                // 6. COMPLETADAS
                SmartCard {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 58
                    gradientStart: "#6E7885"
                    gradientEnd: "#919BA8"
                    badgeIcon: "check"
                    titleText: qsTr("Completadas")
                    showCount: false
                    isSelected: remindersManager.currentFilter === "completed"
                    onClicked: remindersManager.selectSmartList("completed")
                }
            }

            // Suggested List Banner: Compras
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 46
                radius: 10
                visible: !remindersManager.hasGroceriesList && !root.groceriesSuggestionDismissed
                color: sugHover.hovered ? CachyPalette.hoverOverlay : "transparent"

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 4
                    anchors.rightMargin: 4
                    spacing: 9

                    Rectangle {
                        Layout.preferredWidth: 28
                        Layout.preferredHeight: 28
                        radius: 14
                        color: "#28CD41"

                        CachyIcon {
                            anchors.centerIn: parent
                            name: "sparkles"
                            size: 14
                            color: "#FFFFFF"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 1

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Lista sugerida: Compras")
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: CachyPalette.text
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            text: qsTr("Categoriza elementos automáticamente")
                            font.pixelSize: 10
                            color: CachyPalette.textSecondary
                            elide: Text.ElideRight
                        }
                    }

                    Rectangle {
                        Layout.preferredWidth: 20
                        Layout.preferredHeight: 20
                        radius: 10
                        color: addSugHover.hovered ? Qt.darker("#28CD41", 1.1) : "#28CD41"

                        CachyIcon {
                            anchors.centerIn: parent
                            name: "add"
                            size: 12
                            color: "#FFFFFF"
                        }

                        HoverHandler {
                            id: addSugHover
                            cursorShape: Qt.PointingHandCursor
                        }
                        TapHandler {
                            onTapped: {
                                remindersManager.addList(qsTr("Compras"), "#28CD41", "list");
                            }
                        }
                    }
                }

                HoverHandler { id: sugHover }
            }

            // Heading: Mis listas
            Text {
                Layout.fillWidth: true
                Layout.leftMargin: 4
                Layout.topMargin: 2
                text: qsTr("Mis listas")
                font.pixelSize: 11
                font.weight: Font.DemiBold
                color: CachyPalette.textSecondary
            }

            // Custom Lists & Tags Scrollable Area
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true
                contentWidth: width
                contentHeight: sidebarScrollCol.implicitHeight
                boundsBehavior: Flickable.StopAtBounds

                QQC2.ScrollBar.vertical: QQC2.ScrollBar {
                    policy: QQC2.ScrollBar.AsNeeded
                }

                ColumnLayout {
                    id: sidebarScrollCol
                    width: parent.width
                    spacing: 2

                    Repeater {
                        model: remindersManager.listsModel

                        delegate: Rectangle {
                            id: listDelegate
                            required property var model
                            readonly property bool isCurrent: remindersManager.currentFilter === listDelegate.model.id

                            Layout.fillWidth: true
                            Layout.preferredHeight: 32
                            radius: 8
                            color: listDelegate.isCurrent
                                ? (CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(0, 0, 0, 0.09))
                                : (listMouse.containsMouse ? CachyPalette.hoverOverlay : "transparent")

                            Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }

                            MouseArea {
                                id: listMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    if (mouse.button === Qt.RightButton) {
                                        listContextMenu.popup();
                                    } else {
                                        remindersManager.selectCustomList(listDelegate.model.id);
                                    }
                                }
                            }

                            CachyMenu {
                                id: listContextMenu
                                CachyMenuItem {
                                    text: qsTr("Eliminar lista")
                                    iconName: "trash"
                                    destructive: true
                                    onTriggered: remindersManager.deleteList(listDelegate.model.id)
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 7
                                anchors.rightMargin: 9
                                spacing: 8

                                // Colored circle with list icon inside
                                Rectangle {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 22
                                    radius: 11
                                    color: listDelegate.model.color

                                    CachyIcon {
                                        anchors.centerIn: parent
                                        name: "list"
                                        size: 12
                                        color: "#FFFFFF"
                                    }
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: listDelegate.model.name
                                    font.pixelSize: 13
                                    font.weight: listDelegate.isCurrent ? Font.DemiBold : Font.Normal
                                    color: CachyPalette.text
                                    elide: Text.ElideRight
                                }

                                Text {
                                    text: listDelegate.model.count.toString()
                                    font.pixelSize: 12
                                    color: CachyPalette.textSecondary
                                }
                            }
                        }
                    }

                    // Section: Etiquetas
                    Text {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        Layout.topMargin: 14
                        Layout.bottomMargin: 4
                        text: qsTr("Etiquetas")
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: CachyPalette.textSecondary
                    }

                    Flow {
                        Layout.fillWidth: true
                        Layout.leftMargin: 2
                        Layout.rightMargin: 2
                        spacing: 6

                        // All Tags Pill
                        Rectangle {
                            readonly property bool selected: remindersManager.currentFilter === "tags_all"
                            height: 24
                            width: allTagsLabel.implicitWidth + 16
                            radius: 6
                            color: selected
                                ? CachyTheme.accentColor
                                : (allTagsHover.hovered ? CachyPalette.cardBackgroundHover : (CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.07)))
                            border.width: 1
                            border.color: selected ? CachyTheme.accentColor : CachyPalette.specularBorder

                            Text {
                                id: allTagsLabel
                                anchors.centerIn: parent
                                text: qsTr("Todas")
                                font.pixelSize: 11
                                font.weight: Font.Medium
                                color: parent.selected ? "#FFFFFF" : CachyPalette.text
                            }

                            HoverHandler {
                                id: allTagsHover
                                cursorShape: Qt.PointingHandCursor
                            }
                            TapHandler {
                                onTapped: remindersManager.selectTagFilter("")
                            }
                        }

                        // Individual Tag Pills
                        Repeater {
                            model: remindersManager.allTags

                            delegate: Rectangle {
                                id: tagPill
                                required property string modelData
                                readonly property bool selected: remindersManager.currentFilter === ("tag:" + tagPill.modelData)

                                height: 24
                                width: tagPillText.implicitWidth + 16
                                radius: 6
                                color: tagPill.selected
                                    ? CachyTheme.accentColor
                                    : (tagPillHover.hovered ? CachyPalette.cardBackgroundHover : (CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.10) : Qt.rgba(0, 0, 0, 0.07)))
                                border.width: 1
                                border.color: tagPill.selected ? CachyTheme.accentColor : CachyPalette.specularBorder

                                Text {
                                    id: tagPillText
                                    anchors.centerIn: parent
                                    text: tagPill.modelData
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    color: tagPill.selected ? "#FFFFFF" : CachyPalette.text
                                }

                                HoverHandler {
                                    id: tagPillHover
                                    cursorShape: Qt.PointingHandCursor
                                }
                                TapHandler {
                                    onTapped: remindersManager.selectTagFilter(tagPill.modelData)
                                }
                            }
                        }
                    }
                }
            }
        }
    ]

    // =========================================================================
    // 5. RIGHT MAIN CONTENT AREA (Title + Count, Completed Bar & Tasks List)
    // =========================================================================
    contentData: [
        ColumnLayout {
            anchors.fill: parent
            anchors.leftMargin: 22
            anchors.rightMargin: 22
            anchors.topMargin: 6
            anchors.bottomMargin: 12
            spacing: 8

            // Top Header: Large Title (left) + Large Count (right)
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    Layout.fillWidth: true
                    text: remindersManager.currentTitle
                    font.bold: true
                    font.pixelSize: 30
                    color: remindersManager.currentColor
                    elide: Text.ElideRight
                }

                Text {
                    text: remindersManager.currentViewTotalCount.toString()
                    font.pixelSize: 30
                    font.weight: Font.Normal
                    color: remindersManager.currentColor
                }
            }

            // Sub-bar: "X Completados • Limpiar" (left) ... "Mostrar / Ocultar" (right)
            RowLayout {
                Layout.fillWidth: true
                Layout.topMargin: 2
                visible: remindersManager.currentFilter !== "completed"

                Text {
                    text: qsTr("%1 Completados").arg(remindersManager.currentViewCompletedCount)
                    font.pixelSize: 12
                    color: CachyPalette.textSecondary
                }

                Text {
                    text: "•"
                    font.pixelSize: 12
                    color: CachyPalette.textMuted
                    visible: remindersManager.currentViewCompletedCount > 0
                }

                Text {
                    text: qsTr("Limpiar")
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: CachyPalette.accentText
                    visible: remindersManager.currentViewCompletedCount > 0

                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: remindersManager.clearCompletedInCurrentView() }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: remindersManager.showCompleted ? qsTr("Ocultar") : qsTr("Mostrar")
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    color: CachyPalette.accentText
                    visible: remindersManager.currentViewCompletedCount > 0 || remindersManager.showCompleted

                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                    TapHandler { onTapped: remindersManager.showCompleted = !remindersManager.showCompleted }
                }
            }

            // Subtle horizontal divider under sub-bar
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 1
                color: CachyPalette.dividerColor
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
                    spacing: 2

                    // Tap empty background space to start inline draft (macOS Golden Gate)
                    TapHandler {
                        onTapped: point => {
                            if (point.position.y > tasksListView.contentItem.childrenRect.height) {
                                root.startInlineDraft();
                            }
                        }
                    }

                    // Empty State Placeholder
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: 8
                        visible: tasksListView.count === 0 && !root.isDraftActive

                        CachyIcon {
                            Layout.alignment: Qt.AlignHCenter
                            name: "calendar"
                            size: 38
                            color: CachyPalette.textMuted
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: qsTr("No hay recordatorios")
                            font.pixelSize: 15
                            font.weight: Font.DemiBold
                            color: CachyPalette.textSecondary
                        }

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            text: qsTr("Haz clic aquí o pulsa ＋ para añadir uno")
                            font.pixelSize: 12
                            color: CachyPalette.accentText
                        }

                        TapHandler {
                            onTapped: root.startInlineDraft()
                        }
                    }

                    delegate: Rectangle {
                        id: taskRow
                        required property var model
                        required property int index

                        readonly property bool isInspected: taskInspectorPopup.visible && taskInspectorPopup.taskId === taskRow.model.id

                        width: tasksListView.width
                        height: Math.max(38, taskCol.implicitHeight + 14)
                        radius: 8
                        color: (taskRow.isInspected || rowHover.hovered)
                            ? (CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.05))
                            : "transparent"

                        Behavior on color { ColorAnimation { duration: CachyTheme.animFast } }

                        HoverHandler { id: rowHover }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 8
                            anchors.rightMargin: 10
                            anchors.topMargin: 7
                            anchors.bottomMargin: 7
                            spacing: 11

                            // Circular Animated Checkbox
                            Rectangle {
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: 2
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18
                                radius: 9
                                color: taskRow.model.isCompleted ? taskRow.model.listColor : "transparent"
                                border.color: taskRow.model.isCompleted
                                    ? taskRow.model.listColor
                                    : (taskRow.model.isUrgent
                                        ? "#E55882"
                                        : (CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.36) : Qt.rgba(0, 0, 0, 0.28)))
                                border.width: 1.5

                                CachyIcon {
                                    anchors.centerIn: parent
                                    name: "check"
                                    size: 11
                                    color: "#FFFFFF"
                                    visible: taskRow.model.isCompleted
                                }

                                HoverHandler { cursorShape: Qt.PointingHandCursor }
                                TapHandler {
                                    onTapped: remindersManager.toggleCompleted(taskRow.model.id)
                                }
                            }

                            // Task Details (Title, Notes, Tags, DueDate, Urgent, List Badge)
                            ColumnLayout {
                                id: taskCol
                                Layout.fillWidth: true
                                spacing: 3

                                // Title Row with Priority Exclamations
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        visible: taskRow.model.priority > 0
                                        text: taskRow.model.priority === 3 ? "!!!" : (taskRow.model.priority === 2 ? "!!" : "!")
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                        color: remindersManager.currentColor
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: taskRow.model.title
                                        font.pixelSize: 14
                                        font.strikeout: taskRow.model.isCompleted
                                        color: taskRow.model.isCompleted ? CachyPalette.textMuted : CachyPalette.text
                                        elide: Text.ElideRight
                                    }
                                }

                                // Notes
                                Text {
                                    Layout.fillWidth: true
                                    text: taskRow.model.notes
                                    font.pixelSize: 12
                                    color: CachyPalette.textSecondary
                                    visible: taskRow.model.notes.length > 0
                                    wrapMode: Text.WordWrap
                                }

                                // Metadata Row (Tags, DueDate, Urgent, List Badge)
                                Flow {
                                    Layout.fillWidth: true
                                    spacing: 8
                                    visible: taskRow.model.hasDueDate
                                        || taskRow.model.tags.length > 0
                                        || taskRow.model.isUrgent
                                        || (remindersManager.currentFilter !== taskRow.model.listId)

                                    // Tags (blue #tag like macOS Reminders)
                                    Text {
                                        visible: taskRow.model.tags.length > 0
                                        text: taskRow.model.tags
                                        font.pixelSize: 12
                                        color: CachyPalette.accentText
                                    }

                                    // Due Date
                                    Row {
                                        spacing: 4
                                        visible: taskRow.model.hasDueDate

                                        CachyIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            name: "clock"
                                            size: 11
                                            color: taskRow.model.isOverdue ? "#FF3B30" : CachyPalette.textSecondary
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: taskRow.model.dueDateStr
                                            font.pixelSize: 11
                                            color: taskRow.model.isOverdue ? "#FF3B30" : CachyPalette.textSecondary
                                        }
                                    }

                                    // Urgent indicator
                                    Row {
                                        spacing: 3
                                        visible: taskRow.model.isUrgent

                                        CachyIcon {
                                            anchors.verticalCenter: parent.verticalCenter
                                            name: "alarm"
                                            size: 11
                                            color: "#E55882"
                                        }

                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: qsTr("Urgente")
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                            color: "#E55882"
                                        }
                                    }

                                    // List Name Badge (text centered inside its pill Rectangle)
                                    Rectangle {
                                        visible: remindersManager.currentFilter !== taskRow.model.listId
                                        width: listBadgeText.implicitWidth + 12
                                        height: 17
                                        radius: 4.5
                                        color: CachyTheme.withAlpha(taskRow.model.listColor, CachyPalette.isDark ? 0.24 : 0.14)

                                        Text {
                                            id: listBadgeText
                                            anchors.centerIn: parent
                                            text: taskRow.model.listName
                                            font.pixelSize: 10
                                            font.weight: Font.DemiBold
                                            color: taskRow.model.listColor
                                        }
                                    }
                                }
                            }

                            // Right Actions (Flag, Delete, Inspector (i))
                            RowLayout {
                                Layout.alignment: Qt.AlignTop
                                Layout.topMargin: -1
                                spacing: 4

                                // Flag button (always visible if flagged, high-contrast neutral on hover)
                                Rectangle {
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    radius: 12
                                    visible: taskRow.model.isFlagged || rowHover.hovered || taskRow.isInspected
                                    color: flagHover.hovered ? CachyPalette.hoverOverlay : "transparent"

                                    CachyIcon {
                                        anchors.centerIn: parent
                                        name: "flag"
                                        size: 13
                                        color: taskRow.model.isFlagged ? "#FF9500" : CachyPalette.textSecondary
                                    }

                                    HoverHandler {
                                        id: flagHover
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                    TapHandler {
                                        onTapped: remindersManager.toggleFlagged(taskRow.model.id)
                                    }
                                    QQC2.ToolTip.visible: flagHover.hovered
                                    QQC2.ToolTip.text: taskRow.model.isFlagged ? qsTr("Quitar marca") : qsTr("Marcar")
                                    QQC2.ToolTip.delay: 450
                                }

                                // Delete button
                                Rectangle {
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    radius: 12
                                    visible: rowHover.hovered
                                    color: delHover.hovered ? CachyPalette.hoverOverlay : "transparent"

                                    CachyIcon {
                                        anchors.centerIn: parent
                                        name: "trash"
                                        size: 13
                                        color: "#FF3B30"
                                    }

                                    HoverHandler {
                                        id: delHover
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                    TapHandler {
                                        onTapped: remindersManager.deleteReminder(taskRow.model.id)
                                    }
                                    QQC2.ToolTip.visible: delHover.hovered
                                    QQC2.ToolTip.text: qsTr("Eliminar recordatorio")
                                    QQC2.ToolTip.delay: 450
                                }

                                // Inspector button (i) anchored as rightmost action
                                Rectangle {
                                    id: infoBtn
                                    Layout.preferredWidth: 24
                                    Layout.preferredHeight: 24
                                    radius: 12
                                    visible: rowHover.hovered || taskRow.isInspected
                                    color: infoHover.hovered ? CachyPalette.hoverOverlay : "transparent"

                                    CachyIcon {
                                        anchors.centerIn: parent
                                        name: "info"
                                        size: 14
                                        color: CachyTheme.accentColor
                                    }

                                    HoverHandler {
                                        id: infoHover
                                        cursorShape: Qt.PointingHandCursor
                                    }
                                    TapHandler {
                                        onTapped: taskInspectorPopup.openForTask(taskRow.model, infoBtn)
                                    }
                                    QQC2.ToolTip.visible: infoHover.hovered
                                    QQC2.ToolTip.text: qsTr("Mostrar detalles")
                                    QQC2.ToolTip.delay: 450
                                }
                            }
                        }

                        // Bottom subtle separator line
                        Rectangle {
                            visible: !taskRow.isInspected && !rowHover.hovered
                            anchors.bottom: parent.bottom
                            anchors.left: parent.left
                            anchors.leftMargin: 37
                            anchors.right: parent.right
                            height: 1
                            color: CachyPalette.dividerColor
                        }
                    }

                    // Inline Draft Row (macOS Golden Gate Inline Creation)
                    footer: Component {
                        Item {
                            id: draftFooterItem
                            width: tasksListView.width
                            height: root.isDraftActive ? 42 : 0
                            visible: root.isDraftActive
                            clip: true

                            Behavior on height { NumberAnimation { duration: CachyTheme.animFast } }

                            Connections {
                                target: root
                                function onDraftRequested() {
                                    inlineDraftInput.forceActiveFocus();
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.topMargin: 2
                                anchors.bottomMargin: 2
                                radius: 8
                                color: CachyPalette.cardBackgroundHover
                                border.color: CachyTheme.accentColor
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 8
                                    anchors.rightMargin: 12
                                    spacing: 11

                                    Rectangle {
                                        Layout.preferredWidth: 18
                                        Layout.preferredHeight: 18
                                        radius: 9
                                        color: "transparent"
                                        border.color: remindersManager.currentColor
                                        border.width: 1.5
                                    }

                                    TextInput {
                                        id: inlineDraftInput
                                        Layout.fillWidth: true
                                        font.pixelSize: 14
                                        color: CachyPalette.text
                                        clip: true
                                        verticalAlignment: TextInput.AlignVCenter

                                        Text {
                                            text: qsTr("Nuevo recordatorio...")
                                            color: CachyPalette.textMuted
                                            visible: !inlineDraftInput.text && !inlineDraftInput.activeFocus
                                            font.pixelSize: 14
                                            anchors.verticalCenter: parent.verticalCenter
                                        }

                                        Keys.onEscapePressed: {
                                            inlineDraftInput.text = "";
                                            root.isDraftActive = false;
                                        }

                                        onAccepted: {
                                            var val = inlineDraftInput.text.trim();
                                            if (val.length > 0) {
                                                remindersManager.addReminder(val, "", new Date(), false, false, 0);
                                                inlineDraftInput.text = "";
                                                inlineDraftInput.forceActiveFocus();
                                            } else {
                                                root.isDraftActive = false;
                                            }
                                        }

                                        onActiveFocusChanged: {
                                            if (!activeFocus) {
                                                var val = inlineDraftInput.text.trim();
                                                if (val.length > 0) {
                                                    remindersManager.addReminder(val, "", new Date(), false, false, 0);
                                                    inlineDraftInput.text = "";
                                                }
                                                root.isDraftActive = false;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        },

        // =====================================================================
        // TASK INSPECTOR POPOVER (macOS Golden Gate 1:1 Floating Inspector)
        // =====================================================================
        QQC2.Popup {
            id: taskInspectorPopup
            parent: root.overlayItem
            width: 296
            padding: 12
            modal: false
            focus: true
            closePolicy: (listPickerMenu.opened || priorityMenu.opened)
                ? QQC2.Popup.NoAutoClose
                : (QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside)

            property bool isInitializing: false
            property string taskId: ""
            property string taskListId: "default"
            property string taskTitle: ""
            property string taskNotes: ""
            property date taskDueDate: new Date()
            property bool taskHasDate: false
            property bool taskHasTime: false
            property bool taskIsFlagged: false
            property bool taskIsUrgent: false
            property int taskPriority: 0
            property string taskTags: ""
            property bool taskHasLocation: false
            property bool taskWhenMessaging: false
            property bool showDatePickerInline: false
            property bool showTimePickerInline: false
            property real pointerArrowY: 100
            property Item currentAnchorItem: null

            Connections {
                target: root
                function onWidthChanged() {
                    if (taskInspectorPopup.opened) {
                        taskInspectorPopup.updatePopupGeometry();
                    }
                }
                function onHeightChanged() {
                    if (taskInspectorPopup.opened) {
                        taskInspectorPopup.updatePopupGeometry();
                    }
                }
            }

            function selectedListName() {
                return remindersManager.listNameForId(taskListId);
            }

            function selectedListColor() {
                return remindersManager.listColorForId(taskListId);
            }

            function priorityLabel(p) {
                if (p === 1) return qsTr("Baja (!)");
                if (p === 2) return qsTr("Media (!!)");
                if (p === 3) return qsTr("Alta (!!!)");
                return qsTr("Ninguna");
            }

            function updatePopupGeometry() {
                var popH = Math.min(inspColumn.implicitHeight + 24, root.height - 28);
                if (currentAnchorItem) {
                    var pt = currentAnchorItem.mapToItem(root.overlayItem, 0, currentAnchorItem.height / 2);
                    var minX = (root.sidebarVisible ? root.sidebarWidth : 0) + 12;
                    x = Math.max(minX, Math.min(root.width - width - 14, pt.x - width - 14));
                    y = Math.max(14, Math.min(root.height - popH - 14, Math.round(pt.y - popH * 0.35)));
                    pointerArrowY = Math.max(24, Math.min(popH - 24, pt.y - y));
                } else {
                    x = Math.max(16, root.width - width - 20);
                    y = Math.max(14, Math.round((root.height - popH) / 2));
                    pointerArrowY = Math.round(popH / 2);
                }
            }

            function openForTask(taskModel, anchorItem) {
                if (opened && taskId.length > 0 && taskId !== taskModel.id) {
                    saveCurrentTask();
                }

                isInitializing = true;
                currentAnchorItem = anchorItem || null;
                taskId = taskModel.id;
                taskListId = taskModel.listId || "default";
                taskTitle = taskModel.title;
                taskNotes = taskModel.notes;
                taskDueDate = (taskModel.dueDate && !isNaN(taskModel.dueDate.getTime())) ? taskModel.dueDate : new Date();
                taskHasDate = taskModel.hasDueDate;
                taskHasTime = taskModel.hasDueDate && taskModel.hasDueTime;
                taskIsFlagged = taskModel.isFlagged;
                taskIsUrgent = taskModel.isUrgent;
                taskPriority = taskModel.priority;
                taskTags = taskModel.tags || "";
                taskHasLocation = taskModel.hasLocation;
                taskWhenMessaging = taskModel.whenMessaging;
                showDatePickerInline = false;
                showTimePickerInline = false;

                inspTitleInput.text = taskModel.title;
                inspNotesInput.text = taskModel.notes;
                inspTagsInput.text = taskModel.tags || "";

                updatePopupGeometry();

                isInitializing = false;
                open();
            }

            function saveCurrentTask() {
                if (isInitializing || taskId.length === 0) return;
                var newTitle = inspTitleInput.text.trim();
                if (newTitle.length === 0) newTitle = taskTitle;
                remindersManager.updateReminderDetails(
                    taskId,
                    taskListId,
                    newTitle,
                    inspNotesInput.text.trim(),
                    taskDueDate,
                    taskHasDate,
                    taskIsFlagged,
                    taskIsUrgent,
                    taskPriority,
                    inspTagsInput.text.trim(),
                    taskHasTime,
                    taskHasLocation,
                    taskWhenMessaging
                );
            }

            onClosed: {
                saveCurrentTask();
                taskId = "";
                currentAnchorItem = null;
            }

            background: Item {
                Rectangle {
                    id: inspectorCardBg
                    anchors.fill: parent
                    radius: 14
                    color: CachyPalette.sheetBackground
                    border.width: 1
                    border.color: CachyPalette.specularBorder
                    visible: false
                }

                MultiEffect {
                    anchors.fill: inspectorCardBg
                    source: inspectorCardBg
                    shadowEnabled: true
                    shadowBlur: 0.6
                    shadowVerticalOffset: 5
                    shadowHorizontalOffset: 0
                    shadowColor: Qt.rgba(0, 0, 0, CachyPalette.isDark ? 0.55 : 0.22)
                }

                // Right-pointing popover arrow aimed at the (i) info button
                Item {
                    visible: taskInspectorPopup.currentAnchorItem !== null
                    x: parent.width - 1
                    y: taskInspectorPopup.pointerArrowY - 9
                    width: 9
                    height: 18
                    clip: true

                    Rectangle {
                        x: -5.5
                        y: 3.5
                        width: 11
                        height: 11
                        rotation: 45
                        color: CachyPalette.sheetBackground
                        border.width: 1
                        border.color: CachyPalette.specularBorder
                    }
                }
            }

            contentItem: Flickable {
                implicitWidth: 272
                implicitHeight: Math.min(inspColumn.implicitHeight, root.height - 52)
                contentWidth: width
                contentHeight: inspColumn.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: inspColumn
                    width: parent.width
                    spacing: 7

                    onImplicitHeightChanged: {
                        if (taskInspectorPopup.opened) {
                            taskInspectorPopup.updatePopupGeometry();
                        }
                    }

                    // Top Header: Settings Icon + "Editar descripción" + "Listo"
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        CachyIcon {
                            name: "settings"
                            size: 14
                            color: CachyPalette.textSecondary
                        }

                        Text {
                            text: qsTr("Editar descripción")
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: CachyPalette.text
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: qsTr("Listo")
                            font.pixelSize: 12
                            font.weight: Font.DemiBold
                            color: CachyPalette.accentText

                            HoverHandler { cursorShape: Qt.PointingHandCursor }
                            TapHandler { onTapped: taskInspectorPopup.close() }
                        }
                    }

                    // Title Pill ("Título: <value>")
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 30
                        radius: 8
                        color: CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.08) : Qt.rgba(0, 0, 0, 0.06)

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 10
                            anchors.rightMargin: 10
                            spacing: 4

                            Text {
                                text: qsTr("Título:")
                                font.pixelSize: 12
                                color: CachyPalette.textSecondary
                            }

                            TextInput {
                                id: inspTitleInput
                                Layout.fillWidth: true
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                                color: CachyPalette.text
                                clip: true
                                verticalAlignment: TextInput.AlignVCenter
                                onAccepted: taskInspectorPopup.close()
                            }
                        }
                    }

                    // Notes & URL Field
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 40
                        radius: 8
                        color: CachyPalette.isDark ? Qt.rgba(1, 1, 1, 0.06) : Qt.rgba(0, 0, 0, 0.045)

                        TextEdit {
                            id: inspNotesInput
                            anchors.fill: parent
                            anchors.margins: 8
                            wrapMode: TextEdit.Wrap
                            color: CachyPalette.text
                            font.pixelSize: 12
                            clip: true

                            Text {
                                text: qsTr("Notas y URL")
                                color: CachyPalette.textMuted
                                visible: !inspNotesInput.text && !inspNotesInput.activeFocus
                                font.pixelSize: 12
                            }
                        }
                    }

                    // ---------------------------------------------------------
                    // SECTION: FECHA Y HORA
                    // ---------------------------------------------------------
                    Text {
                        text: qsTr("Fecha y hora")
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: CachyPalette.text
                        Layout.topMargin: 2
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: dateTimeGroupCol.implicitHeight
                        radius: 10
                        color: CachyPalette.cardBackground
                        border.width: 1
                        border.color: CachyPalette.specularBorder

                        ColumnLayout {
                            id: dateTimeGroupCol
                            width: parent.width
                            spacing: 0

                            // Row 1: Fecha
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: taskInspectorPopup.taskHasDate ? 36 : 32
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                spacing: 8

                                CachyIcon {
                                    name: "calendar"
                                    size: 14
                                    color: taskInspectorPopup.taskHasDate ? "#007AFF" : CachyPalette.textSecondary
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: qsTr("Fecha")
                                        font.pixelSize: 12
                                        color: CachyPalette.text
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: taskInspectorPopup.taskHasDate
                                        text: Qt.formatDate(taskInspectorPopup.taskDueDate, "d MMM yyyy")
                                        font.pixelSize: 10
                                        color: CachyPalette.accentText
                                        elide: Text.ElideRight

                                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                                        TapHandler {
                                            onTapped: taskInspectorPopup.showDatePickerInline = !taskInspectorPopup.showDatePickerInline
                                        }
                                    }
                                }

                                CachySwitch {
                                    implicitWidth: 36
                                    implicitHeight: 20
                                    checked: taskInspectorPopup.taskHasDate
                                    onToggled: {
                                        taskInspectorPopup.taskHasDate = checked;
                                        if (!checked) {
                                            taskInspectorPopup.taskHasTime = false;
                                            taskInspectorPopup.showDatePickerInline = false;
                                            taskInspectorPopup.showTimePickerInline = false;
                                        } else {
                                            taskInspectorPopup.showDatePickerInline = true;
                                        }
                                    }
                                }
                            }

                            // Inline Date Picker & Quick Chips
                            ColumnLayout {
                                Layout.fillWidth: true
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                Layout.bottomMargin: 8
                                visible: taskInspectorPopup.taskHasDate && taskInspectorPopup.showDatePickerInline
                                spacing: 6

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 6

                                    CachyButton {
                                        text: qsTr("Hoy")
                                        implicitHeight: 24
                                        onClicked: {
                                            var d = new Date();
                                            d.setHours(taskInspectorPopup.taskDueDate.getHours());
                                            d.setMinutes(taskInspectorPopup.taskDueDate.getMinutes());
                                            taskInspectorPopup.taskDueDate = d;
                                        }
                                    }

                                    CachyButton {
                                        text: qsTr("Mañana")
                                        implicitHeight: 24
                                        onClicked: {
                                            var d = new Date();
                                            d.setDate(d.getDate() + 1);
                                            d.setHours(taskInspectorPopup.taskDueDate.getHours());
                                            d.setMinutes(taskInspectorPopup.taskDueDate.getMinutes());
                                            taskInspectorPopup.taskDueDate = d;
                                        }
                                    }
                                }

                                CachyDatePicker {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 248
                                    selectedDate: taskInspectorPopup.taskDueDate
                                    showTodayButton: false
                                    onDateSelected: selected => {
                                        var d = new Date(selected);
                                        d.setHours(taskInspectorPopup.taskDueDate.getHours());
                                        d.setMinutes(taskInspectorPopup.taskDueDate.getMinutes());
                                        taskInspectorPopup.taskDueDate = d;
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 32
                                Layout.preferredHeight: 1
                                color: CachyPalette.dividerColor
                            }

                            // Row 2: Hora
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: taskInspectorPopup.taskHasTime ? 36 : 32
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                spacing: 8

                                CachyIcon {
                                    name: "clock"
                                    size: 14
                                    color: taskInspectorPopup.taskHasTime ? "#007AFF" : CachyPalette.textSecondary
                                }

                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 0

                                    Text {
                                        Layout.fillWidth: true
                                        text: qsTr("Hora")
                                        font.pixelSize: 12
                                        color: CachyPalette.text
                                        elide: Text.ElideRight
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        visible: taskInspectorPopup.taskHasTime
                                        text: Qt.formatTime(taskInspectorPopup.taskDueDate, "HH:mm")
                                        font.pixelSize: 10
                                        color: CachyPalette.accentText
                                        elide: Text.ElideRight

                                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                                        TapHandler {
                                            onTapped: taskInspectorPopup.showTimePickerInline = !taskInspectorPopup.showTimePickerInline
                                        }
                                    }
                                }

                                CachySwitch {
                                    implicitWidth: 36
                                    implicitHeight: 20
                                    checked: taskInspectorPopup.taskHasTime
                                    onToggled: {
                                        taskInspectorPopup.taskHasTime = checked;
                                        if (checked) {
                                            taskInspectorPopup.taskHasDate = true;
                                            taskInspectorPopup.showTimePickerInline = true;
                                        } else {
                                            taskInspectorPopup.showTimePickerInline = false;
                                        }
                                    }
                                }
                            }

                            // Inline Time Picker
                            CachyTimePicker {
                                Layout.alignment: Qt.AlignHCenter
                                Layout.bottomMargin: 8
                                visible: taskInspectorPopup.taskHasTime && taskInspectorPopup.showTimePickerInline
                                hour: taskInspectorPopup.taskDueDate.getHours()
                                minute: taskInspectorPopup.taskDueDate.getMinutes()
                                is24Hour: true
                                onTimeSelected: (h, m) => {
                                    var d = new Date(taskInspectorPopup.taskDueDate);
                                    d.setHours(h);
                                    d.setMinutes(m);
                                    taskInspectorPopup.taskDueDate = d;
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 32
                                Layout.preferredHeight: 1
                                color: CachyPalette.dividerColor
                            }

                            // Row 3: Urgente
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                spacing: 8

                                CachyIcon {
                                    name: "alarm"
                                    size: 14
                                    color: taskInspectorPopup.taskIsUrgent ? "#E55882" : CachyPalette.textSecondary
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Urgente")
                                    font.pixelSize: 12
                                    color: CachyPalette.text
                                }

                                CachySwitch {
                                    implicitWidth: 36
                                    implicitHeight: 20
                                    activeColor: "#E55882"
                                    checked: taskInspectorPopup.taskIsUrgent
                                    onToggled: taskInspectorPopup.taskIsUrgent = checked
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        Layout.rightMargin: 4
                        text: qsTr("Marca este recordatorio como urgente para configurar una alarma.")
                        font.pixelSize: 10
                        color: CachyPalette.textSecondary
                        wrapMode: Text.WordWrap
                    }

                    // ---------------------------------------------------------
                    // SECTION: ORGANIZACIÓN
                    // ---------------------------------------------------------
                    Text {
                        text: qsTr("Organización")
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: CachyPalette.text
                        Layout.topMargin: 2
                    }

                    // Card 1: Lista + Etiquetas
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: orgGroup1Col.implicitHeight
                        radius: 10
                        color: CachyPalette.cardBackground
                        border.width: 1
                        border.color: CachyPalette.specularBorder

                        ColumnLayout {
                            id: orgGroup1Col
                            width: parent.width
                            spacing: 0

                            // Lista selector row
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                spacing: 8

                                CachyIcon {
                                    name: "list"
                                    size: 14
                                    color: CachyPalette.textSecondary
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Lista")
                                    font.pixelSize: 12
                                    color: CachyPalette.text
                                }

                                RowLayout {
                                    id: listPickerAnchor
                                    spacing: 5

                                    Rectangle {
                                        Layout.preferredWidth: 8
                                        Layout.preferredHeight: 8
                                        radius: 4
                                        color: taskInspectorPopup.selectedListColor()
                                    }

                                    Text {
                                        text: taskInspectorPopup.selectedListName()
                                        font.pixelSize: 12
                                        color: CachyPalette.text
                                    }

                                    CachyIcon {
                                        name: "chevron-down"
                                        size: 11
                                        color: CachyPalette.textSecondary
                                    }

                                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: listPickerMenu.popup(listPickerAnchor, 0, listPickerAnchor.height + 4)
                                    }

                                    CachyMenu {
                                        id: listPickerMenu

                                        Repeater {
                                            model: remindersManager.listsModel
                                            delegate: CachyMenuItem {
                                                required property var model
                                                text: model.name
                                                checkable: true
                                                checked: taskInspectorPopup.taskListId === model.id
                                                onTriggered: taskInspectorPopup.taskListId = model.id
                                            }
                                        }
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 32
                                Layout.preferredHeight: 1
                                color: CachyPalette.dividerColor
                            }

                            // Etiquetas row (inline editable #tags)
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                spacing: 8

                                CachyIcon {
                                    name: "tag"
                                    size: 14
                                    color: inspTagsInput.text.trim().length > 0 ? "#007AFF" : CachyPalette.textSecondary
                                }

                                Text {
                                    text: qsTr("Etiquetas")
                                    font.pixelSize: 12
                                    color: CachyPalette.text
                                }

                                TextInput {
                                    id: inspTagsInput
                                    Layout.fillWidth: true
                                    font.pixelSize: 12
                                    color: CachyPalette.accentText
                                    horizontalAlignment: TextInput.AlignRight
                                    verticalAlignment: TextInput.AlignVCenter
                                    clip: true

                                    Text {
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: qsTr("Añadir #etiqueta")
                                        font.pixelSize: 11
                                        color: CachyPalette.textMuted
                                        visible: !inspTagsInput.text && !inspTagsInput.activeFocus
                                    }
                                }
                            }
                        }
                    }

                    // Card 2: Con marca + Prioridad
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: orgGroup2Col.implicitHeight
                        radius: 10
                        color: CachyPalette.cardBackground
                        border.width: 1
                        border.color: CachyPalette.specularBorder

                        ColumnLayout {
                            id: orgGroup2Col
                            width: parent.width
                            spacing: 0

                            // Con marca (Flag)
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                spacing: 8

                                CachyIcon {
                                    name: "flag"
                                    size: 14
                                    color: taskInspectorPopup.taskIsFlagged ? "#FF9500" : CachyPalette.textSecondary
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Con marca")
                                    font.pixelSize: 12
                                    color: CachyPalette.text
                                }

                                CachySwitch {
                                    implicitWidth: 36
                                    implicitHeight: 20
                                    activeColor: "#FF9500"
                                    checked: taskInspectorPopup.taskIsFlagged
                                    onToggled: taskInspectorPopup.taskIsFlagged = checked
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 32
                                Layout.preferredHeight: 1
                                color: CachyPalette.dividerColor
                            }

                            // Prioridad dropdown
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                spacing: 8

                                Text {
                                    Layout.preferredWidth: 14
                                    horizontalAlignment: Text.AlignHCenter
                                    text: "!"
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    color: taskInspectorPopup.taskPriority > 0 ? CachyTheme.accentColor : CachyPalette.textSecondary
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Prioridad")
                                    font.pixelSize: 12
                                    color: CachyPalette.text
                                }

                                RowLayout {
                                    id: prioAnchor
                                    spacing: 4

                                    Text {
                                        text: taskInspectorPopup.priorityLabel(taskInspectorPopup.taskPriority)
                                        font.pixelSize: 12
                                        color: CachyPalette.textSecondary
                                    }

                                    CachyIcon {
                                        name: "chevron-down"
                                        size: 11
                                        color: CachyPalette.textSecondary
                                    }

                                    HoverHandler { cursorShape: Qt.PointingHandCursor }
                                    TapHandler {
                                        onTapped: priorityMenu.popup(prioAnchor, 0, prioAnchor.height + 4)
                                    }

                                    CachyMenu {
                                        id: priorityMenu
                                        CachyMenuItem {
                                            text: qsTr("Ninguna")
                                            checkable: true
                                            checked: taskInspectorPopup.taskPriority === 0
                                            onTriggered: taskInspectorPopup.taskPriority = 0
                                        }
                                        CachyMenuItem {
                                            text: qsTr("Baja (!)")
                                            checkable: true
                                            checked: taskInspectorPopup.taskPriority === 1
                                            onTriggered: taskInspectorPopup.taskPriority = 1
                                        }
                                        CachyMenuItem {
                                            text: qsTr("Media (!!)")
                                            checkable: true
                                            checked: taskInspectorPopup.taskPriority === 2
                                            onTriggered: taskInspectorPopup.taskPriority = 2
                                        }
                                        CachyMenuItem {
                                            text: qsTr("Alta (!!!)")
                                            checkable: true
                                            checked: taskInspectorPopup.taskPriority === 3
                                            onTriggered: taskInspectorPopup.taskPriority = 3
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // ---------------------------------------------------------
                    // SECTION: LUGARES Y PERSONAS
                    // ---------------------------------------------------------
                    Text {
                        text: qsTr("Lugares y personas")
                        font.pixelSize: 11
                        font.weight: Font.DemiBold
                        color: CachyPalette.text
                        Layout.topMargin: 2
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: peopleGroupCol.implicitHeight
                        radius: 10
                        color: CachyPalette.cardBackground
                        border.width: 1
                        border.color: CachyPalette.specularBorder

                        ColumnLayout {
                            id: peopleGroupCol
                            width: parent.width
                            spacing: 0

                            // Ubicación
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                spacing: 8

                                CachyIcon {
                                    name: "location"
                                    size: 14
                                    color: taskInspectorPopup.taskHasLocation ? "#007AFF" : CachyPalette.textSecondary
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Ubicación")
                                    font.pixelSize: 12
                                    color: CachyPalette.text
                                }

                                CachySwitch {
                                    implicitWidth: 36
                                    implicitHeight: 20
                                    checked: taskInspectorPopup.taskHasLocation
                                    onToggled: taskInspectorPopup.taskHasLocation = checked
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.leftMargin: 32
                                Layout.preferredHeight: 1
                                color: CachyPalette.dividerColor
                            }

                            // Al enviar mensaje
                            RowLayout {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                Layout.leftMargin: 10
                                Layout.rightMargin: 10
                                spacing: 8

                                CachyIcon {
                                    name: "message"
                                    size: 14
                                    color: taskInspectorPopup.taskWhenMessaging ? "#34C759" : CachyPalette.textSecondary
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: qsTr("Al enviar mensaje")
                                    font.pixelSize: 12
                                    color: CachyPalette.text
                                }

                                CachySwitch {
                                    implicitWidth: 36
                                    implicitHeight: 20
                                    checked: taskInspectorPopup.taskWhenMessaging
                                    onToggled: taskInspectorPopup.taskWhenMessaging = checked
                                }
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.leftMargin: 4
                        Layout.rightMargin: 4
                        text: qsTr("Al seleccionar esta opción se mostrará el recordatorio al chatear con una persona.")
                        font.pixelSize: 10
                        color: CachyPalette.textSecondary
                        wrapMode: Text.WordWrap
                    }
                }
            }
        }
    ]

    // =========================================================================
    // 6. OVERLAYS (New List Dialog + Feedback Toast)
    // =========================================================================
    overlay: [
        CachyDialog {
            id: newListDialog
            title: qsTr("Nueva lista")
            subtitle: qsTr("Elige un nombre y un color para tu lista de recordatorios.")
            preferredWidth: 340
            cancelText: qsTr("Cancelar")

            property string selectedColor: "#007AFF"

            function openDialog() {
                listNameInput.text = "";
                selectedColor = "#007AFF";
                open();
                listNameInput.forceActiveFocus();
            }

            function confirmCreate() {
                if (listNameInput.text.trim().length > 0) {
                    remindersManager.addList(listNameInput.text.trim(), newListDialog.selectedColor, "list");
                    listNameInput.text = "";
                    newListDialog.close();
                }
            }

            customFooterActions: [
                QQC2.Action {
                    text: qsTr("Crear")
                    enabled: listNameInput.text.trim().length > 0
                    onTriggered: newListDialog.confirmCreate()
                }
            ]

            CachyTextField {
                id: listNameInput
                Layout.fillWidth: true
                placeholderText: qsTr("Nombre de la lista")
                onAccepted: newListDialog.confirmCreate()
            }

            Text {
                text: qsTr("Color de la lista:")
                font.pixelSize: 12
                color: CachyPalette.textSecondary
            }

            RowLayout {
                spacing: 8
                Repeater {
                    model: ["#007AFF", "#FF9500", "#FF3B30", "#34C759", "#AF52DE", "#5856D6", "#FF2D55", "#5AC8FA"]
                    delegate: Rectangle {
                        id: colorSwatch
                        required property string modelData
                        Layout.preferredWidth: 26
                        Layout.preferredHeight: 26
                        radius: 13
                        color: colorSwatch.modelData
                        border.color: (newListDialog.selectedColor === colorSwatch.modelData) ? CachyPalette.text : "transparent"
                        border.width: 2.5

                        HoverHandler { cursorShape: Qt.PointingHandCursor }
                        TapHandler {
                            onTapped: newListDialog.selectedColor = colorSwatch.modelData
                        }
                    }
                }
            }
        },

        CachyToast {
            id: statusToast
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 18
        }
    ]
}
