import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0
import org.meecast.mpvqml 1.0

import mpvobject 1.0
Page {
    id: about
    property alias versiontext: version_label.text
    allowedOrientations: Orientation.All
    Settings {
        id: appSettings
    }

    Component.onCompleted: {
    }

    MpvObject {
        id: renderer_about
        objectName: "renderer_about"
        height: 1
        width: 1
        onPlaybackRestart: {
        }
        onMpvVersionIsDone: {
            versiontext = renderer_about.getMpvVersion()
            renderer_about.command(["quit"])
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height + Theme.paddingLarge

        contentWidth: parent.width

        VerticalScrollDecorator {
        }

        Column {
            id: column
            spacing: Theme.paddingLarge
            width: parent.width
            PageHeader {
                title: qsTrId("About MpvQML")
            }
            SectionHeader {
                text: "MpvQML " + qsTrId("version") + " 0.5 " + qsTrId("based on:")
            }
            TextArea {
                id: version_label
                readOnly: true
            }
        }
    }
}    
