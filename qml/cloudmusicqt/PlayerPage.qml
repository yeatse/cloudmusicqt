import QtQuick 1.1
import com.nokia.symbian 1.1
import QtMultimediaKit 1.1
import com.yeatse.cloudmusic 1.0

Page {
    id: page

    property MusicFetcher currentFetcher: null
    property MusicInfo currentMusic: null
    property int currentIndex: -1

    function playPrivateFM() {
        bringToFront()
        if (currentFetcher != privateFMFetcher || !audio.playing) {
            currentFetcher = privateFMFetcher
            audio.pendingIndex = -1
            privateFMFetcher.reset()
            privateFMFetcher.disconnect()
            privateFMFetcher.loadPrivateFM()
            privateFMFetcher.loadingChanged.connect(privateFMFetcher.firstListLoaded)
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
            iconSource: "toolbar-search"
            onClicked: audio.stop()
        }
    }

    MusicFetcher {
        id: privateFMFetcher

        function disconnect() {
            privateFMFetcher.loadingChanged.disconnect(firstListLoaded)
            privateFMFetcher.loadingChanged.disconnect(listAppended)
        }

        function firstListLoaded() {
            if (loading) return
            disconnect()
            if (currentFetcher == privateFMFetcher && count > 0) {
                if (audio.status == Audio.Loading) {
                    audio.pendingIndex = 0
                }
                else {
                    audio.pendingIndex = -1
                    audio.setCurrentMusic(0)
                }
            }
        }

        function listAppended() {
            if (loading) return
            disconnect()
            if (currentFetcher == privateFMFetcher && currentIndex < count - 1) {
                if (audio.status == Audio.Loading) {
                    audio.pendingIndex = currentIndex + 1
                }
                else {
                    audio.pendingIndex = -1
                    audio.setCurrentMusic(currentIndex + 1)
                }
            }
        }
    }

    Audio {
        id: audio

        volume: volumeIndicator.volume / 100

        property int pendingIndex: -1

        function setCurrentMusic(index) {
            if (currentFetcher != null && index >= 0 && index < currentFetcher.count) {
                currentMusic = currentFetcher.dataAt(index)
                currentIndex = index
                audio.source = currentMusic.getUrl(MusicInfo.LowQuality)
                audio.play()
            }
        }

        function playNextMusic() {
            if (currentFetcher == privateFMFetcher) {
                if (currentIndex >= privateFMFetcher.count - 2 && !privateFMFetcher.loading)
                    privateFMFetcher.loadPrivateFM()

                if (currentIndex < privateFMFetcher.count - 1)
                    setCurrentMusic(currentIndex + 1)
                else {
                    privateFMFetcher.disconnect()
                    privateFMFetcher.loadingChanged.connect(privateFMFetcher.listAppended)
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
            if (status != Audio.Loading) {
                if (pendingIndex != -1) {
                    setCurrentMusic(pendingIndex)
                    pendingIndex = -1
                    return
                }
            }
            console.log(debugStatus(), debugError())
            if (status == Audio.EndOfMedia) {
                playNextMusic()
            }
        }

        onError: {
            console.log(debugError(), errorString, source)
        }
    }
}
