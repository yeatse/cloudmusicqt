import QtQuick 1.1
import com.nokia.symbian 1.1
import com.yeatse.cloudmusic 1.0

import "../js/api.js" as Api

Page {
    id: page

    property string listId
    property bool requstLoad: true

    property string coverImageUrl
    property string name
    property string author

    property int favoriteCount
    property int commentCount
    property int shareCount

    orientationLock: PageOrientation.LockPortrait

    onStatusChanged: {
        if (status == PageStatus.Active && requstLoad) {
            requstLoad = false
            fetcher.loadPlayList(listId)
        }
    }

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

        property string type: "PlayListPage"
        property bool dataValid: false

        onLoadingChanged: {
            if (!loading && !lastError) {
                try {
                    fillMetaData()
                    dataValid = true
                } catch(e){
                    console.log("fill meta data error:" + e.toString())
                }
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

                var rawData = getRawData()
                if (rawData && rawData.result && rawData.specialType == 5) {
                    collector.loadFromFetcher(fetcher)
                }
            }
        }

        function fillMetaData() {
            var ret = getRawData().playlist
            coverImageUrl = Api.getScaledImageUrl(qmlApi.getNetEaseImageUrl(ret.coverImgId), 200)
            name = ret.name
            author = ret.creator.nickname
            favoriteCount = ret.subscribedCount
            commentCount = ret.commentCount
            shareCount = ret.shareCount
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
                title: "歌单"
            }
            Item {
                anchors { left: parent.left; right: parent.right; margins: platformStyle.paddingLarge }
                height: width / 480 * 222
                visible: fetcher.loading || !fetcher.dataValid
                BusyIndicator {
                    anchors.centerIn: parent
                    running: fetcher.loading
                }
                Button {
                    anchors.centerIn: parent
                    iconSource: privateStyle.toolBarIconPath("toolbar-refresh")
                    visible: !fetcher.loading && !fetcher.dataValid
                    onClicked: fetcher.loadPlayList(listId)
                }
            }
            Item {
                anchors { left: parent.left; right: parent.right; margins: platformStyle.paddingLarge }
                height: width / 480 * 222
                visible: !fetcher.loading && fetcher.dataValid
                Image {
                    id: coverImage
                    height: parent.height
                    width: height
                    source: coverImageUrl
                    sourceSize { width: width; height: height }
                }
                ListItemText {
                    id: titleText
                    anchors {
                        left: coverImage.right; leftMargin: platformStyle.paddingMedium
                        top: parent.top; topMargin: platformStyle.paddingSmall
                    }
                    text: name
                }
                ListItemText {
                    anchors {
                        left: titleText.left; top: titleText.bottom
                        topMargin: platformStyle.paddingLarge
                    }
                    role: "SubTitle"
                    color: platformStyle.colorNormalLight
                    text: "By " + author
                }
                ListItemText {
                    anchors {
                        left: titleText.left; bottom: parent.bottom
                        bottomMargin: platformStyle.paddingSmall
                    }
                    role: "SubTitle"
                    text: "收藏%1 评论%2 分享%3".arg(favoriteCount).arg(commentCount).arg(shareCount)
                }
            }
            Button {
                anchors { left: parent.left; right: parent.right; margins: platformStyle.paddingLarge }
                text: "播放全部"
                enabled: !fetcher.loading && fetcher.count > 0
                onClicked: player.playFetcher(fetcher.type, {listId: listId}, fetcher, 0)
            }
        }

        delegate: MusicListItem {
            showIndex: true
            title: name
            subTitle: desc
            active: player.currentMusic != null && player.currentMusic.musicId == musicId
            onClicked: player.playFetcher(fetcher.type, {listId: listId}, fetcher, index)
        }
    }

    ScrollDecorator { flickableItem: listView }
}
