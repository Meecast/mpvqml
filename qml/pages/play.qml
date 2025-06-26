import QtQuick 2.2
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

import mpvobject 1.0
import org.meecast.mpvqml 1.0
import Nemo.KeepAlive 1.2

FullscreenContentPage {
    id: playpage
    allowedOrientations: Orientation.All
    backNavigation: false
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
    property int volume: -1
    property int inactiveBrightness: -1
    property int activeBrightness: -1
    property int brightness: -1
    // ratio for trigger, 1/Xth of minimum dimension
    // for tap gestures this is the distance that must *not* be moved for it to trigger
    property int trigger_rate: 30
    // minimum movement which triggers a Control state
    property int trigger: 0
    property double ss_begin_time_position: -1
    property int last_pos_x: -1
    property int last_pos_y: -1
    property int interval_timer: 1000 // for show volume, britness and other

    Settings {
        id: appSettings
    }

    Component.onCompleted: {
        renderer.get_display_brightness()
        renderer.command(["loadfile", selectedFile])
        fadeRect.folded = true
        timerow.visible = true
        main_column.height = timerow.height + buttons_row.height
        trigger = Math.min(playpage.width, playpage.height) / trigger_rate
    }

    Component.onDestruction: {
        renderer.set_display_brightness(inactiveBrightness)
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

    Timer {
        id: hideVolume
        interval: interval_timer
        running: false
        repeat: false
        onTriggered: {
            volume_label.visible = false
        }
    }

    Timer {
        id: hideBrightness
        interval: interval_timer
        running: false
        repeat: false
        onTriggered: {
            brightness_label.visible = false
        }
    }

    Timer {
        id: hideSS
        interval: interval_timer
        running: false
        repeat: false
        onTriggered: {
            ss_label.visible = false
        }
    }

    MpvObject {
        id: renderer
        anchors.fill: parent
        onFileLoaded: {
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
        onBrightness: {
            if (inactiveBrightness === -1) {
                inactiveBrightness = brightness
                activeBrightness = brightness
            }
            playpage.brightness = brightness
        }


        MouseArea {
            id: mousearea
            anchors.fill: parent
            property int offset_height: page.height/20
            property int offset_width: page.width/20
            property int offsetHeight: height - (offset_height*2)
            property int offsetWidth: width - (offset_width*2)
            property int step_height: offsetHeight / 10
            property int step_width: 2
            property bool stepChanged: false
            property int brightnessStep: 10
            property int lambdaVolumeStep: -1
            property int lambdassStep: -1
            property int beginssStep: -1
            property int endssStep: -1
            property int lambdaBrightnessStep: -1
            property int currentVolume: -1
            property int _ss_direct: -1 // Direction (default value Unknown -1)

            function calculateStep(mouse) {
                return [Math.round((offsetHeight - (mouse.y-offset_height)) / step_height), Math.round((offsetWidth - (mouse.x-offset_width)) / step_width)]
            }

            onReleased: {
                if (!stepChanged){
                    if (fadeRect.folded){
                        fadeRect.folded = false
                    }else{
                        fadeRect.folded = true
                    }
                }
                lambdaVolumeStep = -1
                lambdaBrightnessStep = -1
                lambdassStep = -1
                stepChanged = false
                last_pos_x = -1
                last_pos_y = -1
            }

            onPressed: {
                pacontrol.update()
                var temp = calculateStep(mouse)
                lambdaBrightnessStep = lambdaVolumeStep = temp[0]
                lambdassStep = temp[1]
                beginssStep = endssStep = temp[1]
                _ss_direct = -1  /* Set direction of changing on srceen to status Unknown */
                last_pos_x = mouse.x
                last_pos_y = mouse.y
                ss_begin_time_position = time_position
            }

            Connections {
                target: pacontrol
                onVolumeChanged: {
                    mousearea.currentVolume = volume
                    if (volume > 10) {
                        mousearea.currentVolume = 10
                    } else if (volume < 0) {
                        mousearea.currentVolume = 0
                    }
                }
            }

            onPositionChanged: {
                if (last_pos_x === -1 || last_pos_y === -1)
                    return
                var temp = calculateStep(mouse)
                var step = temp[0]
                var ssStep = temp[1]
                if (_ss_direct === -1){
                    // throttle events: only send updates when there's some movement compared to last update
                    // 4 here is arbitrary
                    if (Math.max(Math.abs(last_pos_x - mouse.x) , Math.abs(last_pos_y - mouse.y)) < trigger / 4)
                        return
                    if (Math.abs(last_pos_x - mouse.x) >  Math.abs(last_pos_y - mouse.y)){
                        _ss_direct = 1 /* Set direction of changing on srceen to status Changing position of playing video */
                    }else{
                        _ss_direct = 0
                    }
                }
                if (_ss_direct === 0){
                    if((mouse.y - offset_height) > 0 && (mouse.y + offset_height) < offsetHeight && mouse.x < mousearea.width/2 && lambdaVolumeStep !== step) {
                        var curVolume = currentVolume - (lambdaVolumeStep - step)
                        pacontrol.setVolume(curVolume)
                        if (curVolume > 10) {
                            curVolume = 10
                        } else if (curVolume < 0) {
                            curVolume = 0
                        }
                        volume_label.text = qsTrId("Volume") + ":" + (curVolume*10) + "%"
                        volume_label.visible = true
                        hideVolume.restart()
                        lambdaVolumeStep = step
                        pacontrol.update()
                        stepChanged = true
                    } else if ((mouse.y - offset_height) > 0 && (mouse.y + offset_height) < offsetHeight && mouse.x > mousearea.width/2 && lambdaBrightnessStep !== step) {
                        renderer.get_display_brightness()
                        var relativeStep = Math.round(playpage.brightness/brightnessStep) - (lambdaBrightnessStep - step)
                        if (relativeStep > 10) relativeStep = 10;
                        if (relativeStep < 0) relativeStep = 0;
                        renderer.set_display_brightness(relativeStep * brightnessStep)
                        activeBrightness = relativeStep * brightnessStep
                        lambdaBrightnessStep = step
                        brightness_label.visible = true
                        brightness_label.text = qsTrId("Brightness") + ":" + (activeBrightness) + "%"
                        hideBrightness.restart()
                        stepChanged = true
                    }
                }else{
                    if (lambdassStep !== ssStep) {
                        var seekstep = lambdassStep - ssStep
                        var new_time_position = -1
                        if (time_position + seekstep > 0){
                            if (time_position + seekstep > duration_time){
                                renderer.command(["seek", duration_time, "absolute+keyframes"])
                                new_time_position = duration_time
                            }else{
                                renderer.command(["seek", (time_position + seekstep), "absolute+keyframes"])
                                new_time_position = time_position + seekstep
                            }
                        }else{
                            renderer.command(["seek", 0, "absolute+keyframes"])
                            new_time_position = 0
                        }
                        //new_time_position = renderer.getProperty("time-pos")
                        endssStep = beginssStep - endssStep + ssStep
                        var diff_step = new_time_position - ss_begin_time_position
                        lambdassStep = ssStep
                        ss_label.visible = true
                        if (new_time_position < 0  || new_time_position == 0){
                            new_time_position = 0
                            diff_step = 0
                        }
                        if (diff_step == 0)
                            ss_label.text = convert_time_to_string(new_time_position) + "\n" + "[" + convert_time_to_string(Math.abs(diff_step)) + "]"
                        else
                            if (diff_step < 0)
                                ss_label.text = convert_time_to_string(new_time_position) + "\n" + "[-" + convert_time_to_string(Math.abs(diff_step)) + "]"
                            else
                                ss_label.text = convert_time_to_string(new_time_position) + "\n" + "[+" + convert_time_to_string(diff_step) + "]"
                            hideSS.restart()
                    }
                }
            }
        }
    }

    Label {
        id: volume_label
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeHuge
        text: ""
        visible: false
    }

    Label {
        id: brightness_label
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeHuge
        text: ""
        visible: false
    }

    Label {
        id: ss_label
        anchors.centerIn: parent
        font.pixelSize: Theme.fontSizeHuge
        text: ""
        visible: false
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
