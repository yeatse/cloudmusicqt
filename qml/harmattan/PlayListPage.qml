import QtQuick 1.1
import com.nokia.meego 1.0
import com.yeatse.cloudmusic 1.0

import "../js/api.js" as Api
import "./UIConstants.js" as UI

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

    property bool subscribed: false

    property string commentId

    orientationLock: PageOrientation.LockPortrait

    onStatusChanged: {
        if (status == PageStatus.Active && requstLoad) {
            requstLoad = false
            fetcher.loadPlayList(listId)
        }
    }

    tools: ToolBarLayout {
        ToolIcon {
            platformIconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
        ToolIcon {
            id: subscribeBtn
            enabled: false
            platformIconId: subscribed ? "toolbar-favorite-mark" : "toolbar-favorite-unmark"
            onClicked: subscribePlaylist(!subscribed)
        }
        ToolIcon {
            platformIconId: "toolbar-new-chat"
            enabled: commentId != ""
            onClicked: pageStack.push(Qt.resolvedUrl("CommentPage.qml"), {commentId: commentId})
        }
        ToolIcon {
            iconSource: "gfx/logo_icon.png"
            onClicked: player.bringToFront()
        }
    }

    function subscribePlaylist(on) {
        if (!subscribeBtn.enabled) return
        if (!user.loggedIn) {
            pageStack.push(Qt.resolvedUrl("LoginPage.qml"))
            return
        }
        var s = function(){
            subscribed = on
            subscribeBtn.enabled = true
        }
        var f = function(err) {
            console.log("subscribe playlist err:", err)
            subscribeBtn.enabled = true
        }
        subscribeBtn.enabled = false
        Api.subscribePlaylist({subscribe: on, id: listId}, s, f)
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
            subscribed = ret.subscribed
            commentId = ret.commentThreadId
            subscribeBtn.enabled = user.loggedIn && ret.creator.userId != qmlApi.getUserId()
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        model: ListModel { id: listModel }
        header: Column {
            width: listView.width
            spacing: UI.PADDING_LARGE
            ViewHeader {
                title: "歌单"
                Button {
                    anchors {
                        right: parent.right; verticalCenter: parent.verticalCenter
                        rightMargin: UI.PADDING_LARGE
                    }
                    platformStyle: ButtonStyle { buttonWidth: buttonHeight }
                    iconSource: "gfx/download.svg"
                    enabled: listView.count > 0
                    onClicked: dlConfirmer.open()
                }
            }
            Item {
                anchors { left: parent.left; right: parent.right; margins: UI.PADDING_LARGE }
                height: width / 480 * 222
                visible: fetcher.loading || !fetcher.dataValid
                BusyIndicator {
                    anchors.centerIn: parent
                    running: fetcher.loading
                }
                Button {
                    anchors.centerIn: parent
                    platformStyle: ButtonStyle { buttonWidth: buttonHeight }
                    iconSource: "image://theme/icon-m-toolbar-refresh-white"
                    visible: !fetcher.loading && !fetcher.dataValid
                    onClicked: fetcher.loadPlayList(listId)
                }
            }
            Item {
                anchors { left: parent.left; right: parent.right; margins: UI.PADDING_LARGE }
                height: width / 480 * 222
                visible: !fetcher.loading && fetcher.dataValid
                Image {
                    id: coverImage
                    height: parent.height
                    width: height
                    source: coverImageUrl
                    sourceSize { width: width; height: height }
                }
                Label {
                    id: titleText
                    anchors {
                        left: coverImage.right; leftMargin: UI.PADDING_MEDIUM
                        top: parent.top; topMargin: UI.PADDING_SMALL
                        right: parent.right
                    }
                    platformStyle: LabelStyle {
                        fontPixelSize: UI.FONT_LARGE
                    }
                    wrapMode: Text.Wrap
                    maximumLineCount: 3
                    text: name
                }
                Label {
                    anchors {
                        left: titleText.left; top: titleText.bottom
                        topMargin: UI.PADDING_LARGE
                    }
                    platformStyle: LabelStyle {
                        fontPixelSize: UI.FONT_SMALL
                    }
                    text: "By " + author
                }
                Label {
                    anchors {
                        left: titleText.left; bottom: parent.bottom
                        bottomMargin: UI.PADDING_SMALL
                    }
                    platformStyle: LabelStyle {
                        fontPixelSize: UI.FONT_SMALL
                        textColor: UI.COLOR_INVERTED_SECONDARY_FOREGROUND
                    }
                    text: "收藏%1 评论%2 分享%3".arg(favoriteCount).arg(commentCount).arg(shareCount)
                }
            }
            Button {
                anchors { left: parent.left; right: parent.right; margins: UI.PADDING_LARGE }
                text: "播放全部"
                enabled: !fetcher.loading && fetcher.count > 0
                onClicked: player.playFetcher(fetcher.type, {listId: listId}, fetcher, -1)
            }
        }

        delegate: MusicListItem {
            showIndex: true
            title: name
            subTitle: desc
            active: player.currentMusic != null && player.currentMusic.musicId == musicId
            onClicked: player.playFetcher(fetcher.type, {listId: listId}, fetcher, index)
            onPressAndHold: contextMenu.init(index)
        }
    }

    PlayListMenu {
        id: contextMenu
        fetcher: fetcher
    }

    QueryDialog {
        id: dlConfirmer
        titleText: "下载确认"
        message: "当前歌单共有%1首歌曲，确定要下载吗？".arg(fetcher.count)
        acceptButtonText: "下载"
        rejectButtonText: "取消"
        onAccepted: {
            for (var i = 0; i < fetcher.count; i++)
                downloader.addTask(fetcher.dataAt(i))

            infoBanner.showMessage("已添加到下载列表")
        }
    }

    ScrollDecorator { flickableItem: listView }
}
