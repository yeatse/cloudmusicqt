import QtQuick 1.1
import com.nokia.symbian 1.1

import "../js/api.js" as Api

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
            for (var i in resp.playlist)
                listModel.append(resp.playlist[i])
        }
        var f = function(err) {
            loadingPlayList = false
            console.log("get user playlist failed: ", err)
        }
        loadingPlayList = true
        Api.getUserPlayList(userId, s, f)
    }

    tools: ToolBarLayout {
        ToolButton {
            iconSource: "toolbar-back"
            onClicked: pageStack.pop()
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
                title: "个人主页"
            }
            Item {
                anchors { left: parent.left; right: parent.right; margins: platformStyle.paddingLarge }
                height: width / 480 * 222
                visible: loadingUserData || !userDataValid
                BusyIndicator {
                    anchors.centerIn: parent
                    running: loadingUserData
                }
                Button {
                    anchors.centerIn: parent
                    iconSource: privateStyle.toolBarIconPath("toolbar-refresh")
                    visible: !loadingUserData && !userDataValid
                    onClicked: loadUserData()
                }
            }
            Item {
                anchors { left: parent.left; right: parent.right; margins: platformStyle.paddingLarge }
                height: 120
                visible: !loadingUserData && userDataValid
                Image {
                    id: avatarImage
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.height
                    height: width
                    source: avatarImageUrl
                    sourceSize { width: width; height: height }
                }
                ListItemText {
                    id: nameLabel
                    anchors {
                        left: avatarImage.right; leftMargin: platformStyle.paddingMedium
                        top: parent.top; topMargin: platformStyle.paddingSmall
                    }
                    text: userName
                }
                ListItemText {
                    id: introLabel
                    anchors {
                        left: nameLabel.left; top: nameLabel.bottom; right: parent.right
                        topMargin: platformStyle.paddingSmall
                    }
                    role: "SubTitle"
                    wrapMode: Text.Wrap
                    maximumLineCount: 2
                    text: signature
                }
                ListItemText {
                    anchors {
                        left: nameLabel.left; bottom: parent.bottom
                        bottomMargin: platformStyle.paddingSmall
                    }
                    role: "SubTitle"
                    text: "动态%1 关注%2 粉丝%3".arg(eventCount).arg(followingCount).arg(followerCount)
                }
            }
            ListHeading {
                ListItemText {
                    anchors.fill: parent.paddingItem
                    role: "Heading"
                    text: "收藏的歌单(%1)".arg(listModel.count)
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
