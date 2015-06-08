import QtQuick 1.1
import com.nokia.meego 1.0
import com.yeatse.cloudmusic 1.0

import "./UIConstants.js" as UI

Page {
    id: page

    orientationLock: PageOrientation.LockPortrait

    tools: ToolBarLayout {
        ToolIcon {
            platformIconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
    }

    onStatusChanged: {
        if (status == PageStatus.Active) {
            searchInput.focus = true
            searchInput.platformOpenSoftwareInputPanel()
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
        implicitWidth: parent.width
        implicitHeight: UI.HEADER_DEFAULT_HEIGHT_PORTRAIT
        z: 1

        SearchInput {
            id: searchInput
            anchors {
                left: parent.left; right: parent.right
                margins: UI.PADDING_LARGE
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
            color: UI.COLOR_INVERTED_BACKGROUND
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

    PlayListMenu {
        id: contextMenu
        fetcher: fetcher
    }

    ScrollDecorator { flickableItem: view }
}
