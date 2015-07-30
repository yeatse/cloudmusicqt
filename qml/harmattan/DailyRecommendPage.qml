import QtQuick 1.1
import com.nokia.meego 1.0
import com.yeatse.cloudmusic 1.0

import "UIConstants.js" as UI

Page {
    id: page

    orientationLock: PageOrientation.LockPortrait

    tools: ToolBarLayout {
        ToolIcon {
            platformIconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
        ToolIcon {
            iconSource: "gfx/logo_icon.png"
            onClicked: player.bringToFront()
        }
    }

    MusicFetcher {
        id: fetcher

        property string type: "DailyRecommendPage"

        onLoadingChanged: {
            if (!loading && lastError == 0) {
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

    ListView {
        id: listView
        anchors.fill: parent
        model: ListModel { id: listModel }
        header: Column {
            width: ListView.view.width
            spacing: UI.PADDING_LARGE
            ViewHeader {
                title: "每日歌曲推荐"
            }
            Image {
                anchors { left: parent.left; right: parent.right; margins: UI.PADDING_LARGE }
                height: width / 480 * 222
                sourceSize { width: width; height: height }
                source: new Date().getDate() % 2 ? "gfx/index_daily_ban1.jpg" : "gfx/index_daily_ban2.jpg"
                Text {
                    anchors {
                        left: parent.left; leftMargin: UI.PADDING_LARGE
                        bottom: parent.bottom; bottomMargin: UI.PADDING_SMALL
                    }
                    font.pixelSize: UI.FONT_SMALL
                    color: "white"
                    text: "根据你的音乐口味生成，每天6:00更新"
                }
                Rectangle {
                    anchors {
                        left: parent.left; leftMargin: UI.PADDING_LARGE
                        top: parent.top; topMargin: UI.PADDING_XLARGE
                    }
                    width: UI.LIST_ITEM_HEIGHT_DEFAULT
                    height: UI.LIST_ITEM_HEIGHT_DEFAULT
                    color: "white"
                    Column {
                        anchors.centerIn: parent
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.pixelSize: UI.FONT_SMALL
                            color: "#e54242"
                            text: Qt.formatDate(new Date(), "dddd")
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.pixelSize: UI.LIST_ITEM_HEIGHT_DEFAULT / 2
                            color: "black"
                            text: new Date().getDate()
                        }
                    }
                }
            }
            Button {
                anchors { left: parent.left; right: parent.right; margins: UI.PADDING_LARGE }
                text: "播放全部"
                enabled: !fetcher.loading && fetcher.count > 0
                onClicked: player.playFetcher(fetcher.type, null, fetcher, -1)
            }
        }

        delegate: MusicListItem {
            title: name
            subTitle: desc
            active: player.currentMusic != null && player.currentMusic.musicId == musicId
            onClicked: player.playFetcher(fetcher.type, null, fetcher, index)
            onPressAndHold: contextMenu.init(index)
        }

        footer: Item {
            width: listView.width
            height: fetcher.loading ? 200 : 0
            BusyIndicator {
                anchors.centerIn: parent
                running: fetcher.loading
                visible: fetcher.loading
            }
        }
    }

    PlayListMenu {
        id: contextMenu
        fetcher: fetcher
    }

    ScrollDecorator { flickableItem: listView }

    Component.onCompleted: fetcher.loadRecommend()
}
