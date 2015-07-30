import QtQuick 1.1
import com.nokia.meego 1.0

import "../js/api.js" as Api
import "./UIConstants.js" as UI

Page {
    id: page

    property string userId
    property bool requestLoad: true

    property bool loadingUserData: false
    property bool loadingPlayList: false
    property bool userDataValid: false

    property string avatarImageUrl
    property string userName
    property int gender // 1 for male, 2 for female
    property int eventCount
    property int followingCount
    property int followerCount
    property string signature
    property int playlistCreated
    property int playlistSubscribed

    orientationLock: PageOrientation.LockPortrait

    onStatusChanged: {
        if (status == PageStatus.Active && requestLoad) {
            requestLoad = false
            loadUserData()
            loadUserPlayList()
        }
    }

    function loadUserData() {
        if (loadingUserData) return;
        var s = function(resp) {
            loadingUserData = false
            var profile = resp.profile
            avatarImageUrl = profile.avatarUrl
            userName = profile.nickname
            gender = profile.gender
            eventCount = profile.eventCount
            followingCount = profile.follows
            followerCount = profile.followeds
            signature = profile.signature
            playlistCreated = profile.cCount
            playlistSubscribed = profile.sCount
            userDataValid = true
        }
        var f = function(err) {
            loadingUserData = false
            console.log("load user data err:", err)
        }
        loadingUserData = true
        Api.getUserDetail(userId, s, f)
    }

    function loadUserPlayList() {
        if (loadingPlayList) return
        var s = function(resp) {
            loadingPlayList = false
            listModel.clear()
            for (var i in resp.playlist) {
                var prop = resp.playlist[i]
                prop.group = prop.creator.userId == userId ? 0 : 1
                listModel.append(prop)
            }
        }
        var f = function(err) {
            loadingPlayList = false
            console.log("get user playlist failed: ", err)
        }
        loadingPlayList = true
        Api.getUserPlayList(userId, s, f)
    }

    tools: ToolBarLayout {
        ToolIcon {
            platformIconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
        ToolButton {
            visible: userId == qmlApi.getUserId()
            text: "登出"
            onClicked: {
                pageStack.pop(app.initialPage)
                user.logout()
            }
        }
        ToolIcon {
            iconSource: "gfx/logo_icon.png"
            onClicked: player.bringToFront()
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
                title: "个人主页"
            }
            Item {
                anchors { left: parent.left; right: parent.right; margins: UI.PADDING_LARGE }
                height: width / 480 * 222
                visible: loadingUserData || !userDataValid
                BusyIndicator {
                    anchors.centerIn: parent
                    running: loadingUserData
                }
                Button {
                    anchors.centerIn: parent
                    platformStyle: ButtonStyle { buttonWidth: buttonHeight }
                    iconSource: "image://theme/icon-m-toolbar-refresh-white"
                    visible: !loadingUserData && !userDataValid
                    onClicked: loadUserData()
                }
            }
            Item {
                anchors { left: parent.left; right: parent.right; margins: UI.PADDING_LARGE }
                height: width / 480 * 222
                visible: !loadingUserData && userDataValid
                Image {
                    id: avatarImage
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.height
                    height: width
                    source: avatarImageUrl
                    sourceSize { width: width; height: height }
                }
                Label {
                    id: nameLabel
                    anchors {
                        left: avatarImage.right; leftMargin: UI.PADDING_MEDIUM
                        top: parent.top; topMargin: UI.PADDING_SMALL
                    }
                    platformStyle: LabelStyle {
                        fontPixelSize: UI.FONT_LARGE
                    }
                    text: userName
                }
                Label {
                    id: introLabel
                    anchors {
                        left: nameLabel.left; top: nameLabel.bottom; right: parent.right
                        topMargin: UI.PADDING_SMALL
                    }
                    platformStyle: LabelStyle {
                        fontPixelSize: UI.FONT_SMALL
                        textColor: UI.COLOR_INVERTED_SECONDARY_FOREGROUND
                    }
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    text: signature
                }
                Label {
                    anchors {
                        left: nameLabel.left; bottom: parent.bottom
                        bottomMargin: UI.PADDING_SMALL
                    }
                    platformStyle: LabelStyle {
                        fontPixelSize: UI.FONT_SMALL
                        textColor: UI.COLOR_INVERTED_SECONDARY_FOREGROUND
                    }
                    text: "动态%1 关注%2 粉丝%3".arg(eventCount).arg(followingCount).arg(followerCount)
                }
            }
            Item { width: 1; height: 1 }
        }
        section {
            property: "group"
            delegate: ListHeading {
                Label {
                    anchors.fill: parent.paddingItem
                    horizontalAlignment: Text.AlignRight
                    verticalAlignment: Text.AlignVCenter
                    text: section == 0 ? "创建的歌单%1".arg(page.playlistCreated)
                                       : "收藏的歌单%1".arg(page.playlistSubscribed)
                }
            }
        }
        delegate: CategoryListItem {
            title: name
            iconSource: Api.getScaledImageUrl(coverImgUrl, 80)
            onClicked: {
                var prop = { listId: id }
                pageStack.push(Qt.resolvedUrl("PlayListPage.qml"), prop)
            }
        }
        footer: Item {
            width: listView.width
            height: loadingPlayList && !loadingUserData ? 200 : 0
            BusyIndicator {
                anchors.centerIn: parent
                running: loadingPlayList && !loadingUserData
                visible: running
            }
        }
    }

    ScrollDecorator { flickableItem: listView }
}
