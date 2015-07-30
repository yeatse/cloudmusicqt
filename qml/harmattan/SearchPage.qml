import QtQuick 1.1
import com.nokia.meego 1.0
import com.yeatse.cloudmusic 1.0

import "./UIConstants.js" as UI

Sheet {
    id: page

    acceptButtonText: "完成";

    property bool _isClosing: false

    onStatusChanged: {
        if (status == DialogStatus.Open) {
            searchInput.focus = true
            searchInput.platformOpenSoftwareInputPanel()
        }
        else if (status == DialogStatus.Closing) {
            _isClosing = true
        }
        else if (status == DialogStatus.Closed && _isClosing) {
            page.destroy(500)
        }
    }

    Component.onCompleted: open()

    title: Label {
        platformStyle: LabelStyle {
            fontPixelSize: UI.FONT_LARGE + 2
        }
        anchors {
            left: parent.left; leftMargin: UI.PADDING_DOUBLE
            verticalCenter: parent.verticalCenter
        }
        text: "搜索歌曲"
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

    content: [
        Item {
            id: viewHeader
            implicitWidth: parent.width
            implicitHeight: UI.HEADER_DEFAULT_HEIGHT_PORTRAIT
            SearchInput {
                id: searchInput
                anchors {
                    left: parent.left; right: parent.right
                    margins: UI.PADDING_LARGE
                    verticalCenter: parent.verticalCenter
                }
                busy: fetcher.loading
                placeholderText: "输入关键词"
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
                color: UI.COLOR_INVERTED_BACKGROUND
            }
        },
        ListView {
            id: view
            anchors { fill: parent; topMargin: viewHeader.height }
            clip: true
            model: ListModel { id: listModel }
            delegate: MusicListItem {
                title: name
                subTitle: desc
                active: player.currentMusic != null && player.currentMusic.musicId == musicId
                onClicked: player.playSingleMusic(fetcher.dataAt(index))
                onPressAndHold: contextMenu.init(index)
            }
        },
        ScrollDecorator {
            flickableItem: view
        }
    ]

    PlayListMenu {
        id: contextMenu
        fetcher: fetcher
    }
}
