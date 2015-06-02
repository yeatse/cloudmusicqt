import QtQuick 1.1
import com.nokia.symbian 1.1
import com.yeatse.cloudmusic 1.0

Page {
    id: page

    orientationLock: PageOrientation.LockPortrait

    tools: ToolBarLayout {
        ToolButton {
            iconSource: "toolbar-back"
            onClicked: pageStack.pop()
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Deactivating) {
            app.forceActiveFocus()
        }
        else if (status == PageStatus.Active) {
            searchInput.forceActiveFocus()
            searchInput.openSoftwareInputPanel()
        }
    }

    MusicFetcher {
        id: fetcher
        property string searchText
        onLoadingChanged: {
            if (!loading && !lastError) {
                contextMenu.close()
                listModel.clear()
                for (var i = 0; i < count; i++) {
                    var data = dataAt(i)
                    var prop = {
                        musicId: data.musicId,
                        name: data.musicName,
                        desc: data.artistsDisplayName + " - " + data.albumName
                    }
                    listModel.append(prop)
                }
            }
        }
    }

    Item {
        id: viewHeader
        implicitWidth: screen.width
        implicitHeight: platformStyle.graphicSizeLarge
        z: 1

        SearchInput {
            id: searchInput
            anchors {
                left: parent.left; right: parent.right
                margins: platformStyle.paddingLarge
                verticalCenter: parent.verticalCenter
            }
            busy: fetcher.loading
            placeholderText: "搜索歌曲"
            onTypeStopped: {
                var searchText = text.trim()
                if (fetcher.searchText == searchText)
                    return

                fetcher.searchText = searchText
                if (searchText == "") {
                    fetcher.reset()
                    listModel.clear()
                }
                else {
                    fetcher.searchSongs(searchText)
                }
            }
        }

        Rectangle {
            anchors.bottom: parent.bottom
            width: parent.width
            height: 1
            color: platformStyle.colorDisabledMid
        }
    }

    ListView {
        id: view
        clip: true
        anchors { fill: parent; topMargin: viewHeader.height }
        model: ListModel { id: listModel }
        delegate: MusicListItem {
            title: name
            subTitle: desc
            active: player.currentMusic != null && player.currentMusic.musicId == musicId
            onClicked: player.playSingleMusic(fetcher.dataAt(index))
            onPressAndHold: contextMenu.init(index)
        }
    }

    ContextMenu {
        id: contextMenu
        property int index
        property bool downloaded
        function init(idx) {
            index = idx
            downloaded = downloader.containsRecord(fetcher.dataAt(index).musicId)
            open()
        }
        MenuLayout {
            MenuItem {
                text: contextMenu.downloaded ? "查看下载" : "下载"
                onClicked: {
                    var data = fetcher.dataAt(contextMenu.index)
                    if (data) {
                        if (contextMenu.downloaded) {
                            pageStack.push(Qt.resolvedUrl("DownloadPage.qml"), { startId: data.musicId })
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

    ScrollDecorator { flickableItem: view }
}
