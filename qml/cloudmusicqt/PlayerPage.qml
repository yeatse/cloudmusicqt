import QtQuick 1.1
import com.nokia.symbian 1.1
import QtMultimediaKit 1.1
import com.yeatse.cloudmusic 1.0
import "../js/util.js" as Util

Page {
    id: page

    property string currentListId: ""
    property int currentIndex: -1
    property MusicInfo currentMusic: null

    property string listIdPrivateFM: "PrivateFM"

    function playPrivateFM() {
        bringToFront()
        if (currentListId != listIdPrivateFM || !audio.playing) {
            currentListId = listIdPrivateFM
            musicFetcher.reset()
            musicFetcher.disconnect()
            musicFetcher.loadPrivateFM()
            musicFetcher.loadingChanged.connect(musicFetcher.firstListLoaded)
        }
        else if (audio.paused) {
            audio.play()
        }
    }

    function bringToFront() {
        if (app.pageStack.currentPage != page) {
            if (app.pageStack.find(function(p){ return p == page }))
                app.pageStack.pop(page)
            else
                app.pageStack.push(page)
        }
    }

    orientationLock: PageOrientation.LockPortrait

    tools: ToolBarLayout {
        ToolButton {
            iconSource: "toolbar-back"
            onClicked: pageStack.pop()
        }
        ToolButton {
            iconSource: "gfx/instant_messenger_chat.svg"
        }
        ToolButton {
            iconSource: "toolbar-menu"
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            app.forceActiveFocus()
        }
    }

    MusicFetcher {
        id: musicFetcher

        function disconnect() {
            loadingChanged.disconnect(firstListLoaded)
            loadingChanged.disconnect(privateFMListAppended)
        }

        function firstListLoaded() {
            if (loading) return
            disconnect()
            if (count > 0) {
                if (audio.status == Audio.Loading) {
                    audio.waitingIndex = 0
                }
                else {
                    audio.waitingIndex = -1
                    audio.setCurrentMusic(0)
                }
            }
        }

        function privateFMListAppended() {
            if (loading) return
            disconnect()
            if (currentListId == listIdPrivateFM && currentIndex < count - 1) {
                if (audio.status == Audio.Loading)
                    audio.waitingIndex = currentIndex + 1
                else {
                    audio.waitingIndex = -1
                    audio.setCurrentMusic(currentIndex + 1)
                }
            }
        }
    }

    Audio {
        id: audio

        property int waitingIndex: -1

        volume: volumeIndicator.volume / 100

        function setCurrentMusic(index) {
            if (index >= 0 && index < musicFetcher.count) {
                currentMusic = musicFetcher.dataAt(index)
                currentIndex = index
                audio.source = currentMusic.getUrl(MusicInfo.LowQuality)
                audio.play()
            }
        }

        function playNextMusic() {
            if (currentListId == listIdPrivateFM) {
                if (currentIndex >= musicFetcher.count - 2 && !musicFetcher.loading)
                    musicFetcher.loadPrivateFM()

                if (currentIndex < musicFetcher.count - 1)
                    setCurrentMusic(currentIndex + 1)
                else {
                    musicFetcher.disconnect()
                    musicFetcher.loadingChanged.connect(musicFetcher.privateFMListAppended)
                }
            }
        }

        function debugStatus() {
            switch (status) {
            case Audio.NoMedia: return "no media"
            case Audio.Loading: return "loading"
            case Audio.Loaded: return "loaded"
            case Audio.Buffering: return "buffering"
            case Audio.Stalled: return "stalled"
            case Audio.Buffered: return "buffered"
            case Audio.EndOfMedia: return "end of media"
            case Audio.InvalidMedia: return "invalid media"
            case Audio.UnknownStatus: return "unknown status"
            default: return ""
            }
        }

        function debugError() {
            switch (error) {
            case Audio.NoError: return "no error"
            case Audio.ResourceError: return "resource error"
            case Audio.FormatError: return "format error"
            case Audio.NetworkError: return "network error"
            case Audio.AccessDenied: return "access denied"
            case Audio.ServiceMissing: return "service missing"
            default: return ""
            }
        }

        onStatusChanged: {
            console.log("audio status changed:", debugStatus(), debugError())
            if (status != Audio.Loading) {
                if (waitingIndex >= 0 && waitingIndex < musicFetcher.count) {
                    setCurrentMusic(waitingIndex)
                    waitingIndex = -1
                    return
                }
            }
            if (status == Audio.EndOfMedia) {
                playNextMusic()
            }
        }

        onError: {
            console.log("error occured:", debugError(), errorString, source)
            if (error == Audio.AccessDenied)
                playNextMusic()
        }
    }

    Flickable {
        id: view
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: Math.max(parent.height, 550)
        boundsBehavior: Flickable.StopAtBounds

        Image {
            id: coverImage
            anchors {
                top: parent.top; topMargin: platformStyle.graphicSizeSmall
                horizontalCenter: parent.horizontalCenter
            }
            width: Math.min(screen.width, screen.height) - platformStyle.graphicSizeSmall * 2
            height: width
            fillMode: Image.PreserveAspectCrop
            source: currentMusic ? currentMusic.albumImageUrl + "?param=640y640&quality=100" : ""
        }

        ProgressBar {
            id: progressBar
            anchors {
                left: coverImage.left; right: coverImage.right
                top: coverImage.bottom
            }
            value: audio.position / audio.duration * 1.0
            indeterminate: audio.status == Audio.Loading || audio.status == Audio.Stalled
                           || (!audio.playing && musicFetcher.loading)
        }

        Text {
            id: positionLabel
            anchors {
                left: progressBar.left; top: progressBar.bottom
            }
            font.pixelSize: platformStyle.fontSizeSmall
            color: platformStyle.colorNormalMid
            text: Util.formatTime(audio.position)
        }

        Text {
            anchors {
                right: progressBar.right; top: progressBar.bottom
            }
            font.pixelSize: platformStyle.fontSizeSmall
            color: platformStyle.colorNormalMid
            text: currentMusic ? Util.formatTime(currentMusic.musicDuration) : "00:00"
        }
        Item {
            anchors {
                top: positionLabel.bottom; bottom: controlButton.top
                left: parent.left; right: parent.right
            }
            Column {
                anchors.centerIn: parent
                spacing: platformStyle.paddingMedium
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: platformStyle.colorNormalLight
                    font.pixelSize: platformStyle.fontSizeLarge
                    text: currentMusic ? currentMusic.musicName : ""
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: platformStyle.colorNormalMid
                    font.pixelSize: platformStyle.fontSizeSmall
                    font.weight: Font.Light
                    text: currentMusic ? currentMusic.artistsDisplayName : ""
                }
            }
        }

        Row {
            id: controlButton

            anchors {
                bottom: parent.bottom; bottomMargin: platformStyle.paddingLarge
                horizontalCenter: parent.horizontalCenter
            }

            spacing: 12

            ControlButton {
                buttonName: currentMusic && currentMusic.starred ? "loved" : "love"
                onClicked: qmlApi.takeScreenShot()
            }

            ControlButton {
                buttonName: audio.playing && !audio.paused ? "pause" : "play"
                onClicked: {
                    if (audio.playing) {
                        if (audio.paused) audio.play()
                        else audio.pause()
                    }
                }
            }

            ControlButton {
                buttonName: "next"
                onClicked: {
                    if (audio.status != Audio.Loading)
                        audio.playNextMusic()
                }
            }

            ControlButton {
                buttonName: "del"
            }
        }
    }
}
