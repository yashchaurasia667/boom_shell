// components/TodoList.qml
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland

import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtCore

import qs.common
import qs.components

PanelWindow {
  id: root
  property int panelMargins: 10
  property string compFont: "Maple Mono NF CN"

  anchors {
    right: true
    bottom: true
  }

  implicitWidth: 400 + panelMargins
  implicitHeight: 400 + panelMargins
  aboveWindows: false
  color: "transparent"

  WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
  BackgroundEffect.blurRegion: Region {
    x: clippingRect.x
    y: clippingRect.y
    width: clippingRect.width
    height: clippingRect.height
    radius: clippingRect.radius
  }

  // Persistent Storage configuration (explicit location avoids QSettings missing organizationName warning)
  Settings {
    id: settings
    location: "file://" + Quickshell.env("HOME") + "/.config/quickshell/todo-list.conf"
    category: "TodoList"
    property string savedTasks: "[]"
  }

  Component.onCompleted: loadTasks()

  ClippingRectangle {
    id: clippingRect

    anchors.fill: parent
    anchors.rightMargin: root.panelMargins
    anchors.bottomMargin: root.panelMargins

    radius: 12
    color: Qt.rgba(Theme.m3surface.r, Theme.m3surface.g, Theme.m3surface.b, 0.75)
    border.color: Theme.m3inverse_on_surface
    border.width: 2

    ColumnLayout {
      anchors.fill: parent
      anchors.margins: 12
      spacing: 6

      // Header
      RowLayout {
        Layout.fillWidth: true

        Label {
          text: "To-Do List"
          color: Theme.m3on_surface
          font.family: compFont
          font.pixelSize: 16
          font.bold: true
        }
        Item { Layout.fillWidth: true }

        Label {
          font.family: compFont
          text: todoModel.count + " items"
          color: Theme.m3on_surface
          font.pixelSize: 12
        }
      }

      // Add Items
      RowLayout {
        Layout.fillWidth: true
        spacing: 8

        TextField {
          id: taskInput
          Layout.fillWidth: true
          font.family: compFont
          font.pixelSize: 13

          placeholderText: "Add a new task.."
          placeholderTextColor: Theme.m3primary
          color: Theme.m3on_surface

          background: Rectangle {
            color: Theme.m3inverse_on_surface
            radius: 6
          }

          onAccepted: root.addTask()
        }
        Button {
          text: "+"
          implicitWidth: 20

          background: Rectangle {
            color: parent.hovered ? Theme.m3on_primary_container : Theme.m3primary
            radius: 8
          }

          contentItem: Text {
            text: parent.text
            font.family: compFont
            color: Theme.m3inverse_on_surface
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            font.bold: true
          }

          onClicked: root.addTask()
        }
      }

      // List View
      ListView {
        id: listView
        Layout.fillWidth: true
        Layout.fillHeight: true
        spacing: 6
        clip: true

        model: ListModel {
          id: todoModel
        }

        delegate: Rectangle {
          required property string taskText
          required property bool isCompleted
          required property int index

          width: listView.width
          height: 30
          color: Theme.m3on_secondary
          radius: 6
          clip: true

          RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Global.pad / 2

            CheckBox {
              checked: isCompleted
              font.family: compFont
              onToggled: {
                todoModel.setProperty(index, "isCompleted", checked)
                root.saveTasks() // Save on toggle
              }
            }

            Label {
              Layout.fillWidth: true
              font.family: compFont
              text: taskText
              color: isCompleted ? Theme.m3primary : Theme.m3on_surface
              font.strikeout: isCompleted
            }

            Button {
              text: "✕"
              implicitWidth: 28
              implicitHeight: 28

              background: Rectangle {
                color: "transparent"
              }

              contentItem: Text {
                text: "✕"
                font.family: compFont
                color: Theme.m3error
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
              }

              onClicked: {
                todoModel.remove(index)
                root.saveTasks() // Save on delete
              }
            }
          }
        }
      }
    }
  }

  // Logic Functions
  function addTask() {
    if (taskInput.text.trim() !== "") {
      todoModel.append({
        "taskText": taskInput.text.trim(),
        "isCompleted": false
      })
      taskInput.text = ""
      saveTasks() // Save on add
    }
  }

  function saveTasks() {
    let tasks = []
    for (let i = 0; i < todoModel.count; i++) {
      let item = todoModel.get(i)
      tasks.push({
        taskText: item.taskText,
        isCompleted: item.isCompleted
      })
    }
    settings.savedTasks = JSON.stringify(tasks)
  }

  function loadTasks() {
    todoModel.clear()
    try {
      let tasks = JSON.parse(settings.savedTasks)
      for (let i = 0; i < tasks.length; i++) {
        todoModel.append(tasks[i])
      }
    } catch (e) {
      console.log("Failed to parse saved tasks:", e)
    }
  }
}
