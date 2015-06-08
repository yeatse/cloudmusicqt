import QtQuick 1.1
import com.nokia.meego 1.0
import com.yeatse.cloudmusic 1.0

ContextMenu {
    id: root

    property MusicFetcher fetcher
    property int index
    property bool downloaded

    function init(idx) {
        index = idx
        downloaded = downloader.containsRecord(fetcher.dataAt(index).musicId)
        open()
    }

    MenuLayout {
        MenuItem {
            text: root.downloaded ? "查看下载" : "下载"
            onClicked: {
                var data = fetcher.dataAt(root.index)
                if (data) {
                    if (root.downloaded) {
                        var prop = { startId: data.musicId,
                            defaultTab: downloader.getCompletedFile(data.musicId) ? 1 : 0 }
                        pageStack.push(Qt.resolvedUrl("DownloadPage.qml"), prop)
                    }
                    else {
                        downloader.addTask(data)
                        infoBanner.showMessage("已添加到下载列表")
                    }
                }
            }
        }
    }
}
