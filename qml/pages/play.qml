import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

import mpvobject 1.0
import org.meecast.mpvqml 1.0
import Nemo.KeepAlive 1.2

FullscreenContentPage {
    id: playpage
    allowedOrientations: Orientation.All
    property string selectedFile: ""
    property double duration_time
    property double time_position
    property bool seek_slider_pressed : false
    property variant speeds: [0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0]
    property int index_speed : 2
    property bool prevent_blanking_display: false 
    property variant subs: [] 
    property variant videos: [] 
    property variant audios: [] 
    property int current_sub: -1
    property int current_audio: -1

    Settings {
        id: appSettings
    }

    Component.onCompleted: {
        renderer.command(["loadfile", selectedFile])
        fadeRect.folded = true
        timerow.visible = true
        main_column.height = timerow.height + buttons_row.height
    }

    function savePosition(){
        if (appSettings.savePosition && (!(renderer.getProperty("eof-reached")))){
            renderer.command(["write-watch-later-config"])
        }
    }

    function convert_time_to_string(_time){
        var hours = 0
        var minutes = 0
        var seconds = 0
        hours = parseInt(_time/(60*60));
        minutes = parseInt((_time-(hours*60*60))/(60));
        seconds = parseInt((_time-(minutes*60)-(hours*60*60)));
        if (hours == 0){
            var result = ("0" + minutes).slice(-2) + ":" + ("0" + seconds).slice(-2) 
        }else{
            var result = ("0" + hours).slice(-2) + ":" + ("0" + minutes).slice(-2) + ":" + ("0" + seconds).slice(-2) 
        }
        return result
    }

    DisplayBlanking {
        preventBlanking: prevent_blanking_display
    }

    MpvObject {
        id: renderer
        anchors.fill: parent
        onFileLoaded: {
           console.log("onFileLoaded")
           var count = renderer.getProperty("track-list/count")

           var item = {mpvid: {"mpvid":-1, "langid":"", "title":"no"}}
           for ( var i = 0; i < count; i++){
               var type = renderer.getProperty("track-list/" + i + "/type") 
               if (type == "")
                    continue
               var mpvid = renderer.getProperty("track-list/" + i + "/id")
               var langid = renderer.getProperty("track-list/" + i + "/lang")
               var title = renderer.getProperty("track-list/" + i + "/title")
               var item = {mpvid: {"mpvid":mpvid, "langid":langid, "title":title}}
               if (type == "sub"){
                   subs.push(item)
               } 
               if (type == "audio"){
                   audios.push(item)
               } 
               if (type == "video"){
                   videos.push(item)
               } 
           }
           item = {mpvid: {"mpvid":-1, "langid":"", "title":qsTrId("OFF")}}
           subs.push(item)
           audios.push(item)
        }

        onPlaybackRestart: {
            if (renderer.getProperty("pause")){
                play_button.icon.source = "image://theme/icon-m-play"
                prevent_blanking_display = false
            }else{
                prevent_blanking_display = true
            }
            duration_time = renderer.getProperty("duration")
            duration.text = convert_time_to_string(duration_time)
            time_position = renderer.getProperty("time-pos")
            timeprogressbar.value = time_position
            time_pos.text = convert_time_to_string(time_position)
            var new_speed = renderer.getProperty("speed")
            text_speed.text = new_speed.toFixed(2) + "X"
            index_speed = 2 /* defaut spped = 1.00 */
            for ( var i = 0; i < speeds.length; i++){
                if (speeds[i] == new_speed){
                    index_speed = i
                }
            }
        }
        onUpdateTimePos: {
            if (!fadeRect.folded){
                if (!seek_slider_pressed)
                    timeprogressbar.value = _time
                time_position = _time
                time_pos.text = convert_time_to_string(_time)
            }
        }
        onUpdateDuration: {
            duration_time = _time
            duration.text = convert_time_to_string(_time)
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                if (fadeRect.folded){
                    fadeRect.folded = false
                }else{
                    fadeRect.folded = true
                }
            }
        }
    }
    Rectangle {
        id: fadeRect
        anchors.fill: parent
        width: parent.width
        color: "transparent"
        property bool folded: false
        IconButton {
            y: Theme.paddingLarge
            anchors {
                right: parent.right
                rightMargin: Theme.paddingSmall
            }
            icon.source: "image://theme/icon-m-dismiss"
            onClicked: {
                savePosition()
                renderer.command(["quit"])
                pageStack.pop()
            }
        }
        Column{
            id: main_column
            height: buttons_row.height
            width: parent.width
            anchors.bottom: parent.bottom
            Rectangle{
                height: Theme.itemSizeSmall
                width: parent.width
                id: timerow
                visible: false
                color: "transparent"
                Label {
                    id: time_pos
                    anchors.bottom: parent.bottom
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.paddingSmall
                    height: Theme.itemSizeSmall
                    text: ""
                }
                Slider {
                    id: timeprogressbar
                    minimumValue: 0
                    maximumValue: duration_time
                    anchors.left: time_pos.right
                    anchors.right: duration.left
                    value: 0
                    onPressedChanged: {
                        if (!pressed){
                            var res_time = timeprogressbar.sliderValue - time_position
                            renderer.command(["seek", res_time, "relative"])
                            seek_slider_pressed = false
                        }else{
                            seek_slider_pressed = true
                        }
                    }
                }
                Label {
                    id: duration
                    anchors.bottom: parent.bottom
                    anchors.right: parent.right
                    anchors.rightMargin: Theme.paddingSmall
                    height: Theme.itemSizeSmall
                    text: ""
                }
            }
            Row{ 
                //width: parent.width
                visible: true 
                height: Theme.itemSizeSmall
                id: buttons_row
                spacing: Theme.paddingLarge
                anchors.horizontalCenter: parent.horizontalCenter
                /*
                Rectangle {
                    id: null_button
                    color: "transparent"
                    width: play_button.height
                    height: play_button.height
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                        }
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        id: text_null
                        text: ""
                    }
                }
                */
                IconButton {
                    id: audio_item
                    width: play_button.height
                    height: Theme.itemSizeSmall
                    visible: true
                    icon.source: "image://theme/icon-m-file-audio"
                    onClicked: {
                        if (current_audio == -1){
                            current_audio = audios[0]["mpvid"]["mpvid"]
                            Notices.show(qsTrId("Audio") + " #" + audios[0]["mpvid"]["langid"] + " " + audios[0]["mpvid"]["title"], Notice.Short, Notice.Center)
                        }else{
                            var myflag = false
                            for(var value in audios){
                                if (myflag){
                                    current_audio = audios[value]["mpvid"]["mpvid"]
                                    Notices.show(qsTrId("Audio") + " #" + audios[value]["mpvid"]["langid"] + " " + audios[value]["mpvid"]["title"], Notice.Short, Notice.Center)
                                    myflag = false
                                    break
                                }
                                if (audios[value]["mpvid"]["mpvid"] == current_audio){
                                    myflag = true
                                }    
                            }
                            if (myflag){
                                current_audio = audios[0]["mpvid"]["mpvid"]
                                Notices.show(qsTrId("Audio") + " #" + audios[0]["mpvid"]["langid"] + " " + audios[0]["mpvid"]["title"], Notice.Short, Notice.Center)
                            }
                        }
                        if (current_audio == -1)
                            renderer.setProperty("audio", "no")
                        else{
                            renderer.setProperty("audio", current_audio)
                        }

                    }
                }

                IconButton {
                    id: sub_items
                    width: play_button.height
                    height: Theme.itemSizeSmall
                    visible: true
                    icon.source: "image://theme/icon-m-browser-popup"
                    onClicked: {
                        if (current_sub == -1){
                            current_sub = subs[0]["mpvid"]["mpvid"]
                            Notices.show(qsTrId("Subtitle") + " #" + subs[0]["mpvid"]["langid"] + " " + subs[0]["mpvid"]["title"], Notice.Short, Notice.Center)
                        }else{
                            var myflag = false
                            for(var value in subs){
                                if (myflag){
                                    current_sub = subs[value]["mpvid"]["mpvid"]
                                    Notices.show(qsTrId("Subtitle") + " #" + subs[value]["mpvid"]["langid"] + " " + subs[value]["mpvid"]["title"], Notice.Short, Notice.Center)
                                    myflag = false
                                    break
                                }
                                if (subs[value]["mpvid"]["mpvid"] == current_sub){
                                    myflag = true
                                }    
                            }
                            if (myflag){
                                current_sub = subs[0]["mpvid"]["mpvid"]
                                Notices.show(qsTrId("Subtitle") + " #" + subs[0]["mpvid"]["langid"] + " " + subs[0]["mpvid"]["title"], Notice.Short, Notice.Center)
                            }
                        }
                        if (current_sub == -1)
                            renderer.setProperty("sub", "no")
                        else{
                            renderer.setProperty("sub", current_sub)
                        }
                        //renderer.setProperty("sub", 2)
                    }
                }

                IconButton {
                    id: back_button_10s
                    width: play_button.height
                    height: Theme.itemSizeSmall
                    visible: true
                    icon.source: "image://theme/icon-m-10s-back"
                    onClicked: {
                        renderer.command(["seek", -10.0])
                    }
                }

                IconButton {
                    id: play_button
                    width: play_button.height
                    height: Theme.itemSizeSmall
                    visible: true
                    icon.source: "image://theme/icon-m-pause"
                    onClicked: {
                        renderer.command(["cycle", "pause"])
                        if (icon.source == "image://theme/icon-m-play"){
                            prevent_blanking_display = true
                            icon.source = "image://theme/icon-m-pause"
                        }else{
                            prevent_blanking_display = false
                            savePosition()
                            icon.source = "image://theme/icon-m-play"
                            fadeRect.folded = !fadeRect.folded
                        }
                    }
                }
                IconButton {
                    id: forward_button_10s
                    width: play_button.height
                    height: Theme.itemSizeSmall
                    visible: true
                    icon.source: "image://theme/icon-m-10s-forward"
                    onClicked: {
                        renderer.command(["seek", 10.0, "relative"])
                    }
                }

                Rectangle {
                    id: speed_button
                    color: "transparent"
                    width: play_button.height
                    height: play_button.height
                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (index_speed < speeds.length - 1){
                                index_speed = index_speed + 1
                            }else{
                                index_speed = 0
                            }
                            var new_speed = speeds[index_speed] 
                            text_speed.text = new_speed.toFixed(2) + "X"
                            renderer.setProperty("speed", new_speed)
                        }
                    }
                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        id: text_speed
                        text: "1.00X"
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }
        }
        state: !folded ? "Visible" : "Invisible"
        states: [
            State{
                name: "Visible"
                PropertyChanges{target: fadeRect; opacity: 1.0}
                PropertyChanges{target: fadeRect; visible: true}
            },
            State{
                name:"Invisible"
                PropertyChanges{target: fadeRect; opacity: 0.0}
                PropertyChanges{target: fadeRect; visible: false}
            }
        ]
        transitions: [
            Transition {
                from: "Visible"
                to: "Invisible"

                SequentialAnimation{
                    NumberAnimation {
                        target: fadeRect
                        property: "opacity"
                        duration: 500
                        easing.type: Easing.InOutQuad
                    }
                    NumberAnimation {
                        target: fadeRect
                        property: "visible"
                        duration: 0
                    }
                }
            },

            Transition {
                from: "Invisible"
                to: "Visible"
                SequentialAnimation{
                    NumberAnimation {
                        target: fadeRect
                        property: "visible"
                        duration: 0
                    }
                    NumberAnimation {
                        target: fadeRect
                        property: "opacity"
                        duration: 500
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        ]
    }
}
