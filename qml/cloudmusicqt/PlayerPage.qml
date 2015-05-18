import QtQuick 1.1
import com.nokia.symbian 1.1
import QtMultimediaKit 1.1
import com.yeatse.cloudmusic 1.0
import "../js/util.js" as Util
import "../js/api.js" as Api

Page {
    id: page

    property string callerType: ""
    property variant callerParam: null

    property int currentIndex: -1
    property MusicInfo currentMusic: null

    property string callerTypePrivateFM: "PrivateFM"
    property string callerTypeDJ: "DJ"
    property string callerTypeDownload: "DownloadPage"

    property bool isMusicCollected: false
    property bool isMusicCollecting: false
    property bool isMusicDownloaded: false

    function playPrivateFM() {
        bringToFront()
        if (callerType != callerTypePrivateFM || !audio.playing) {
            callerType = callerTypePrivateFM
            callerParam = null

            musicFetcher.reset()
            musicFetcher.disconnect()
            musicFetcher.loadPrivateFM()
            musicFetcher.loadingChanged.connect(musicFetcher.firstListLoaded)
        }
        else if (audio.paused) {
            audio.play()
        }
    }

    function playFetcher(type, param, fetcher, index) {
        if (type == callerType && qmlApi.compareVariant(param, callerParam)
                && currentIndex == index && audio.playing)
        {
            if (audio.paused) audio.play()
            else bringToFront()
            return
        }

        callerType = type
        callerParam = param

        musicFetcher.disconnect()
        musicFetcher.loadFromFetcher(fetcher)

        if (audio.status == Audio.Loading)
            audio.waitingIndex = index
        else
            audio.setCurrentMusic(index)
    }

    function playDJ(djId) {
        if (callerType != callerTypeDJ || !qmlApi.compareVariant(callerParam, djId) || !audio.playing) {
            callerType = callerTypeDJ
            callerParam = djId

            musicFetcher.reset()
            musicFetcher.disconnect()
            musicFetcher.loadDJDetail(djId)
            musicFetcher.loadingChanged.connect(musicFetcher.firstListLoaded)
        }
        else if (audio.paused) {
            audio.play()
        }
        else {
            bringToFront()
        }
    }

    function playDownloader(index) {
        callerType = callerTypeDownload
        callerParam = null

        musicFetcher.disconnect()
        musicFetcher.loadFromDownloader()

        if (audio.status == Audio.Loading)
            audio.waitingIndex = index
        else
            audio.setCurrentMusic(index)
    }

    function bringToFront() {
        if (app.pageStack.currentPage != page) {
            if (app.pageStack.find(function(p){ return p == page }))
                app.pageStack.pop(page)
            else
                app.pageStack.push(page)
        }
    }

    function collectCurrentRadio(like) {
        if (callerType != callerTypePrivateFM || currentMusic == null)
            return

        if (!user.loggedIn) {
            pageStack.push(Qt.resolvedUrl("LoginPage.qml"))
            return
        }

        var opt = { id: currentMusic.musicId, like: like, sec: Math.floor(audio.position / 1000) }
        var s = function() {
            isMusicCollected = like
            collector.loadList()
            isMusicCollecting = false
        }
        var f = function(err) {
            isMusicCollecting = false
            console.log("like radio err", err)
        }
        isMusicCollecting = true
        Api.collectRadioMusic(opt, s, f)
    }

    function addCurrentRadioToTrash() {
        if (callerType != callerTypePrivateFM || currentMusic == null)
            return

        var opt = { id: currentMusic.musicId, sec: Math.floor(audio.position / 1000) }
        Api.addRadioMusicToTrash(opt, collector.loadList, new Function())
    }

    orientationLock: PageOrientation.LockPortrait

    onStatusChanged: {
        if (status == PageStatus.Active) {
            app.forceActiveFocus()
        }
    }

    Connections {
        target: collector
        onDataChanged: {
            isMusicCollected = currentMusic != null && collector.isCollected(currentMusic.musicId)
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
                if (audio.status == Audio.Loading)
                    audio.waitingIndex = 0
                else
                    audio.setCurrentMusic(0)
            }
        }

        function privateFMListAppended() {
            if (loading) return
            disconnect()
            if (callerType == callerTypePrivateFM && currentIndex < count - 1) {
                if (audio.status == Audio.Loading)
                    audio.waitingIndex = currentIndex + 1
                else
                    audio.setCurrentMusic(currentIndex + 1)
            }
        }
    }

    Audio {
        id: audio

        property int waitingIndex: -1

        volume: volumeIndicator.volume / 100

        function setCurrentMusic(index) {
            waitingIndex = -1
            if (index >= 0 && index < musicFetcher.count) {
                currentMusic = musicFetcher.dataAt(index)
                currentIndex = index

                var loc = downloader.getCompletedFile(currentMusic.musicId)
                if (qmlApi.isFileExists(loc)) {
                    audio.source = "file:///" + loc
                }
                else if (callerType == callerTypeDownload) {
                    playNextMusic()
                    return
                }
                else {
                    audio.source = currentMusic.getUrl(MusicInfo.LowQuality)
                }
                audio.play()

                isMusicCollecting = false
                if (callerType == callerTypePrivateFM)
                    isMusicCollected = currentMusic.starred
                else
                    isMusicCollected = collector.isCollected(currentMusic.musicId)

                isMusicDownloaded = downloader.containsRecord(currentMusic.musicId)

                if (app.pageStack.currentPage != page || !Qt.application.active) {
                    qmlApi.showNotification("网易云音乐",
                                            "正在播放: %1 - %2".arg(currentMusic.artistsDisplayName).arg(currentMusic.musicName),
                                            1)
                }
            }
        }

        function playNextMusic() {
            if (callerType == callerTypePrivateFM) {
                if (currentIndex >= musicFetcher.count - 2 && !musicFetcher.loading)
                    musicFetcher.loadPrivateFM()

                if (currentIndex < musicFetcher.count - 1)
                    setCurrentMusic(currentIndex + 1)
                else {
                    musicFetcher.disconnect()
                    musicFetcher.loadingChanged.connect(musicFetcher.privateFMListAppended)
                }
            }
            else if (musicFetcher.count == 0) {
                playPrivateFM()
            }
            else {
                if (currentIndex < musicFetcher.count - 1)
                    setCurrentMusic(currentIndex + 1)
                else if (callerType != callerTypeDownload)
                    setCurrentMusic(0)
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
                    return
                }
            }

            if (status == Audio.Stalled) {
                timeoutListener.restart()
            }
            else {
                timeoutListener.stop()
            }

            if (status == Audio.EndOfMedia) {
                playNextMusic()
            }
        }

        onError: {
            console.log("error occured:", debugError(), errorString, source)
            if (error == Audio.ResourceError || error == Audio.FormatError || error == Audio.AccessDenied)
                playNextMusic()
        }
    }

    Timer {
        id: timeoutListener
        interval: 10 * 1000
        onTriggered: audio.playNextMusic()
    }

    Flickable {
        id: view
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: Math.max(screen.height - privateStyle.statusBarHeight,
                                Math.min(screen.width, screen.height) + 200)
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
            source: currentMusic ? Api.getScaledImageUrl(currentMusic.albumImageUrl, 640) : ""
        }

        Image {
            visible: coverImage.status != Image.Ready
            anchors.fill: coverImage
            sourceSize { width: width; height: height }
            source: "gfx/default_play_cover.png"
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
                anchors.verticalCenter: parent.verticalCenter
                width: parent.width
                spacing: platformStyle.paddingMedium
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
                    color: platformStyle.colorNormalLight
                    font.pixelSize: platformStyle.fontSizeLarge
                    text: currentMusic ? currentMusic.musicName : ""
                }
                Text {
                    width: parent.width
                    horizontalAlignment: Text.AlignHCenter
                    wrapMode: Text.Wrap
                    elide: Text.ElideRight
                    maximumLineCount: 2
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
                bottom: parent.bottom; bottomMargin: privateStyle.toolBarHeightPortrait
                horizontalCenter: parent.horizontalCenter
            }

            spacing: 12

            ControlButton {
                buttonName: collector.loading || isMusicCollecting
                            ? "loved_dis" : isMusicCollected ? "loved" : "love"
                visible: callerType != callerTypeDJ && currentMusic != null
                enabled: !(collector.loading || isMusicCollecting)
                onClicked: {
                    if (callerType == callerTypePrivateFM)
                        collectCurrentRadio(!isMusicCollected)
                    else if (callerType == callerTypeDJ)
                        infoBanner.showDevelopingMsg()
                    else if (isMusicCollected)
                        collector.removeCollection(currentMusic.musicId)
                    else
                        collector.collectMusic(currentMusic.musicId)
                }
            }

            ControlButton {
                buttonName: audio.playing && !audio.paused ? "pause" : "play"
                onClicked: {
                    if (audio.playing) {
                        if (audio.paused) audio.play()
                        else audio.pause()
                    }
                    else if (musicFetcher.count > 0) {
                        var index = Math.min(Math.max(currentIndex, 0), musicFetcher.count - 1)
                        if (audio.status == Audio.Loading)
                            audio.waitingIndex = index
                        else
                            audio.setCurrentMusic(index)
                    }
                    else {
                        playPrivateFM()
                    }
                }
            }

            ControlButton {
                buttonName: "next"
                enabled: audio.status != Audio.Loading
                onClicked: audio.playNextMusic()
            }

            ControlButton {
                visible: callerType == callerTypePrivateFM && currentMusic != null
                buttonName: "del"
                enabled: audio.status != Audio.Loading
                onClicked: {
                    addCurrentRadioToTrash()
                    audio.playNextMusic()
                }
            }
        }
    }

    ToolBar {
        id: toolBar
        y: screen.height - privateStyle.statusBarHeight - toolBar.height
        tools: ToolBarLayout {
            ToolButton {
                iconSource: "toolbar-back"
                onClicked: pageStack.pop()
            }
            ToolButton {
                iconSource: "toolbar-menu"
                onClicked: menu.open()
            }
        }
        Component.onCompleted: {
            for (var i = 0; i < children.length; i++) {
                if (children[i].hasOwnProperty("source")) {
                    children[i].source = ""
                    break
                }
            }
        }
    }

    Menu {
        id: menu
        MenuLayout {
            MenuItem {
                enabled: currentMusic != null
                text: currentMusic == null || !isMusicDownloaded ? "下载" : "查看下载"
                onClicked: {
                    if (isMusicDownloaded) {
                        pageStack.push(Qt.resolvedUrl("DownloadPage.qml"))
                    }
                    else {
                        downloader.addTask(currentMusic)
                        isMusicDownloaded = true
                    }
                }
            }
            MenuItem {
                enabled: callerType != "" && callerType != callerTypeDJ && callerType != callerTypePrivateFM
                text: "播放列表"
                onClicked: pageStack.push(Qt.resolvedUrl(callerType + ".qml"), callerParam)
            }
            MenuItem {
                text: "评论"
                onClicked: infoBanner.showDevelopingMsg()
            }
        }
        onStatusChanged: {
            if (status == DialogStatus.Closed)
                app.focus = true
        }
    }
}
