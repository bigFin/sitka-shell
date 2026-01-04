pragma ComponentBehavior: Bound

import qs.components
import qs.components.controls
import qs.services
import "../../../config"
import Quickshell
import Quickshell.Io
import QtQuick
import QtQuick.Layouts

ColumnLayout {
    id: root

    spacing: Config.appearance.spacing.small

    // Persistent todo storage
    PersistentProperties {
        id: storage
        reloadableId: "todoList"

        property string todosJson: "[]"
    }

    // Parse and manage todos
    property var todos: {
        try {
            return JSON.parse(storage.todosJson)
        } catch (e) {
            return []
        }
    }

    function saveTodos(): void {
        storage.todosJson = JSON.stringify(todos)
    }

    function addTodo(text: string): void {
        if (text.trim().length === 0) return
        todos.push({
            id: Date.now(),
            text: text.trim(),
            completed: false
        })
        todosChanged()
        saveTodos()
    }

    function toggleTodo(id: int): void {
        const idx = todos.findIndex(t => t.id === id)
        if (idx >= 0) {
            todos[idx].completed = !todos[idx].completed
            todosChanged()
            saveTodos()
        }
    }

    function deleteTodo(id: int): void {
        const idx = todos.findIndex(t => t.id === id)
        if (idx >= 0) {
            todos.splice(idx, 1)
            todosChanged()
            saveTodos()
        }
    }

    function clearCompleted(): void {
        root.todos = todos.filter(t => !t.completed)
        saveTodos()
    }

    // Header
    RowLayout {
        Layout.fillWidth: true
        spacing: Config.appearance.spacing.small

        StyledText {
            text: qsTr("Todo List")
            font.weight: 600
            font.pointSize: Config.appearance.font.size.normal
            color: Colours.palette.m3onSurface
        }

        Item { Layout.fillWidth: true }

        // Clear completed button
        StyledRect {
            visible: todos.some(t => t.completed)
            implicitWidth: clearText.implicitWidth + Config.appearance.padding.normal * 2
            implicitHeight: clearText.implicitHeight + Config.appearance.padding.small
            radius: Config.appearance.rounding.small
            color: "transparent"

            StyledText {
                id: clearText
                anchors.centerIn: parent
                text: qsTr("Clear done")
                font.pointSize: Config.appearance.font.size.smaller
                color: Colours.palette.m3primary
            }

            StateLayer {
                radius: parent.radius
                function onClicked(): void {
                    root.clearCompleted()
                }
            }
        }
    }

    // Add todo input
    RowLayout {
        Layout.fillWidth: true
        spacing: Config.appearance.spacing.small

        StyledRect {
            Layout.fillWidth: true
            implicitHeight: inputField.implicitHeight + Config.appearance.padding.small * 2
            radius: Config.appearance.rounding.normal
            color: Colours.palette.m3surfaceContainerHigh

            TextInput {
                id: inputField
                anchors.fill: parent
                anchors.margins: Config.appearance.padding.small
                verticalAlignment: TextInput.AlignVCenter

                color: Colours.palette.m3onSurface
                selectionColor: Colours.palette.m3primary
                selectedTextColor: Colours.palette.m3onPrimary
                font.family: Config.appearance.font.family.sans
                font.pointSize: Config.appearance.font.size.small

                property string placeholderText: qsTr("Add a task...")

                Text {
                    anchors.fill: parent
                    verticalAlignment: Text.AlignVCenter
                    text: inputField.placeholderText
                    color: Colours.palette.m3onSurfaceVariant
                    font: inputField.font
                    visible: !inputField.text && !inputField.activeFocus
                }

                Keys.onReturnPressed: {
                    root.addTodo(text)
                    text = ""
                }
                Keys.onEnterPressed: Keys.onReturnPressed(event)
            }
        }

        // Add button
        StyledRect {
            implicitWidth: implicitHeight
            implicitHeight: addIcon.implicitHeight + Config.appearance.padding.small * 2
            radius: Config.appearance.rounding.normal
            color: Colours.palette.m3primary

            MaterialIcon {
                id: addIcon
                anchors.centerIn: parent
                text: "add"
                color: Colours.palette.m3onPrimary
                font.pointSize: Config.appearance.font.size.normal
            }

            StateLayer {
                radius: parent.radius
                color: Colours.palette.m3onPrimary
                function onClicked(): void {
                    root.addTodo(inputField.text)
                    inputField.text = ""
                }
            }
        }
    }

    // Todo items
    ColumnLayout {
        Layout.fillWidth: true
        spacing: 2
        visible: todos.length > 0

        Repeater {
            model: root.todos

            TodoItem {
                required property var modelData
                required property int index

                Layout.fillWidth: true
                todoId: modelData.id
                text: modelData.text
                completed: modelData.completed
                onToggle: root.toggleTodo(todoId)
                onRemove: root.deleteTodo(todoId)
            }
        }
    }

    // Empty state
    StyledText {
        visible: todos.length === 0
        text: qsTr("No tasks yet")
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Config.appearance.font.size.small
    }

    // Stats
    StyledText {
        visible: todos.length > 0
        text: {
            const completed = todos.filter(t => t.completed).length
            const total = todos.length
            return qsTr("%1 of %2 completed").arg(completed).arg(total)
        }
        color: Colours.palette.m3onSurfaceVariant
        font.pointSize: Config.appearance.font.size.smaller
    }

    component TodoItem: StyledRect {
        id: item

        required property int todoId
        required property string text
        required property bool completed

        signal toggle()
        signal remove()

        implicitHeight: itemRow.implicitHeight + Config.appearance.padding.small * 2
        radius: Config.appearance.rounding.small
        color: item.completed
            ? Qt.alpha(Colours.palette.m3primaryContainer, 0.3)
            : Colours.palette.m3surfaceContainerHigh

        RowLayout {
            id: itemRow
            anchors.fill: parent
            anchors.margins: Config.appearance.padding.small
            spacing: Config.appearance.spacing.small

            // Checkbox
            StyledRect {
                implicitWidth: 20
                implicitHeight: 20
                radius: Config.appearance.rounding.small
                color: item.completed
                    ? Colours.palette.m3primary
                    : "transparent"
                border.width: item.completed ? 0 : 2
                border.color: Colours.palette.m3outline

                MaterialIcon {
                    anchors.centerIn: parent
                    visible: item.completed
                    text: "check"
                    color: Colours.palette.m3onPrimary
                    font.pointSize: 12
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: item.toggle()
                }
            }

            // Text
            StyledText {
                Layout.fillWidth: true
                text: item.text
                color: item.completed
                    ? Colours.palette.m3onSurfaceVariant
                    : Colours.palette.m3onSurface
                font.pointSize: Config.appearance.font.size.small
                font.strikeout: item.completed
                elide: Text.ElideRight
            }

            // Delete button
            MaterialIcon {
                text: "close"
                color: Colours.palette.m3onSurfaceVariant
                font.pointSize: Config.appearance.font.size.small
                opacity: deleteArea.containsMouse ? 1 : 0.5

                MouseArea {
                    id: deleteArea
                    anchors.fill: parent
                    anchors.margins: -4
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: item.remove()
                }

                Behavior on opacity {
                    NumberAnimation { duration: 150 }
                }
            }
        }
    }
}
