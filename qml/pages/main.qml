import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

Page {
    id: mainpage
    objectName: "mainpage"
    allowedOrientations: Orientation.All
    property bool seek_slider_pressed : false

    Connections {
        target: dbusAdaptor
        onFileOpenRequested: { mainpage.openFile(path) }
    }

    Component.onCompleted: {
    }

    function openFile(path) {
        pageStack.push(Qt.resolvedUrl("play.qml"), {selectedFile: path})
    }

    Column {
        id: column
        spacing: Theme.paddingLarge
        width: parent.width
        topPadding: Theme.paddingLarge
        Image {
            anchors {
                horizontalCenter: parent.horizontalCenter
            }
            source: "../images/icon.png"
            fillMode: Image.PreserveAspectFit
            width: implicitWidth / 1.5 
            height: implicitHeight / 1.5
        }
        ButtonLayout {
            Button {
                preferredWidth: Theme.buttonWidthMedium
                text: qsTrId("Play file")
                icon.source: "image://theme/icon-m-file-folder"
                onClicked: pageStack.push(filePickerPage)
            }
            Button {
                preferredWidth: Theme.buttonWidthMedium
                text: qsTrId("Play URL")
                icon.source: "image://theme/icon-m-link"
                onClicked: pageStack.push(urlInputPage)
            }
            Button {
                preferredWidth: Theme.buttonWidthMedium
                text: qsTrId("Settings")
                icon.source: "image://theme/icon-m-developer-mode"
                onClicked: pageStack.push(Qt.resolvedUrl("settings.qml"))
            }

        }
    }

    Component {
         id: filePickerPage
         FilePickerPage {
             allowedOrientations: Orientation.All
             nameFilters: [ '*.*' ]
             onSelectedContentPropertiesChanged: {
                 mainpage.openFile(selectedContentProperties.filePath)
             }
         }
     }
    Component {
         id: urlInputPage
         Page {
            id: urlinputpage
            PageHeader {
                title: qsTrId("Open URL")
            }
            TextField {
                focus: true
                anchors.centerIn: parent
                id: urlinput
                label: qsTrId("Input URL")
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: mainpage.openFile(urlinput.text)
            }
            Button {
                anchors.horizontalCenter: parent.horizontalCenter
                preferredWidth: Theme.buttonWidthMedium
                anchors.top: urlinput.bottom
                text: qsTrId("Ok")
                icon.source: "image://theme/icon-m-link"
                onClicked: mainpage.openFile(urlinput.text)
            }
         }
     }
}
