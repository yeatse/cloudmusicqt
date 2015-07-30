import QtQuick 1.1
import com.nokia.meego 1.0
import com.yeatse.cloudmusic 1.0

SelectionDialog {
    id: root

    property MusicFetcher fetcher
    property int index
    property bool downloaded

    function init(idx) {
        index = idx
        var data = fetcher.dataAt(index)
        titleText = data.musicName
        downloaded = downloader.containsRecord(data.musicId)
        model.clear()
        model.append({name: downloaded ? "查看下载" : "下载"})
        selectedIndex = -1
        open()
    }

    onAccepted: {
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
