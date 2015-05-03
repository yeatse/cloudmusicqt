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
        ToolButton {
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
            width: listView.width
            spacing: platformStyle.paddingLarge
            ViewHeader {
                title: "每日歌曲推荐"
            }
            Image {
                anchors { left: parent.left; right: parent.right; margins: platformStyle.paddingLarge }
                height: width / 480 * 222
                sourceSize { width: width; height: height }
                source: new Date().getDate() % 2 ? "gfx/index_daily_ban1.jpg" : "gfx/index_daily_ban2.jpg"
                Text {
                    anchors {
                        left: parent.left; leftMargin: platformStyle.paddingLarge
                        bottom: parent.bottom; bottomMargin: platformStyle.paddingSmall
                    }
                    font.pixelSize: platformStyle.fontSizeSmall
                    color: "white"
                    text: "根据你的音乐口味生成，每天6:00更新"
                }
                Rectangle {
                    anchors {
                        left: parent.left; leftMargin: platformStyle.paddingLarge
                        top: parent.top; topMargin: platformStyle.paddingLarge * 2
                    }
                    width: platformStyle.graphicSizeLarge
                    height: platformStyle.graphicSizeLarge
                    color: "white"
                    Column {
                        anchors.centerIn: parent
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.pixelSize: platformStyle.fontSizeSmall
                            color: "#e54242"
                            text: Qt.formatDate(new Date(), "dddd")
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            font.pixelSize: platformStyle.graphicSizeLarge / 2
                            color: "black"
                            text: new Date().getDate()
                        }
                    }
                }
            }
            Button {
                anchors { left: parent.left; right: parent.right; margins: platformStyle.paddingLarge }
                text: "播放全部"
                enabled: !fetcher.loading && fetcher.count > 0
                onClicked: player.playFetcher(fetcher.type, null, fetcher, 0)
            }
        }

        delegate: MusicListItem {
            title: name
            subTitle: desc
            active: player.currentMusic != null && player.currentMusic.musicId == musicId
            onClicked: player.playFetcher(fetcher.type, null, fetcher, index)
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

    ScrollDecorator { flickableItem: listView }

    Component.onCompleted: fetcher.loadRecommend()
}
