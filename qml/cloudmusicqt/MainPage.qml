import QtQuick 1.1
import com.nokia.symbian 1.1
import com.yeatse.cloudmusic 1.0

import "../js/api.js" as Api

Page {
    id: mainPage

    orientationLock: PageOrientation.LockPortrait

    property bool loading: false

    function getHotSpotList() {
        if (loading) return
        var s = function(resp) {
            loading = false
            hotSpotModel.clear()
            for (var i in resp.data)
                hotSpotModel.append(resp.data[i])
        }
        var f = function(err) {
            loading = false
            console.log("get hot spot failed: ", err)
        }
        loading = true
        Api.getHotSopt(s, f)
    }

    tools: ToolBarLayout {
        ToolButton {
            iconSource: "toolbar-back"
            onClicked: quitTimer.running ? Qt.quit() : quitTimer.start()
            Timer {
                id: quitTimer
                interval: infoBanner.timeout
                onRunningChanged: if (running) infoBanner.showMessage("再按一次退出")
            }
        }

        ToolButton {
            iconSource: "toolbar-search"
            onClicked: infoBanner.showDevelopingMsg()
        }

        ToolButton {
            iconSource: "toolbar-menu"
            onClicked: mainMenu.open()
        }
    }

    Connections {
        target: user
        onUserChanged: getHotSpotList()
    }

    Menu {
        id: mainMenu
        MenuLayout {
            MenuItem {
                text: "下载管理"
                onClicked: pageStack.push(Qt.resolvedUrl("DownloadPage.qml"))
            }
            MenuItem {
                text: "一般设定"
                onClicked: infoBanner.showDevelopingMsg()
            }
            MenuItem {
                text: "关于"
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
        }
        onStatusChanged: {
            if (status == DialogStatus.Closed)
                app.focus = true
        }
    }

    Flickable {
        id: view
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: contentColumn.height

        Column {
            id: contentColumn
            width: parent.width

            ViewHeader {
                id: viewHeader
                ToolButton {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    iconSource: "gfx/contacts.svg"
                    onClicked: user.loggedIn ? pageStack.push(Qt.resolvedUrl("UserInfoPage.qml"),{userId: qmlApi.getUserId()})
                                             : pageStack.push(Qt.resolvedUrl("LoginPage.qml"))
                }
            }

            CategoryListItem {
                property variant music: player.currentMusic
                visible: music != null
                iconSource: music ? Api.getScaledImageUrl(music.albumImageUrl, 80) : ""
                title: "正在播放"
                subTitle: music ? music.artistsDisplayName + " - " + music.musicName : ""
                onClicked: player.bringToFront()
            }

            CategoryListItem {
                iconSource: "gfx/private_radio_icon.png"
                title: "私人FM"
                subTitle: "放松下来，享受你的专属推荐"
                onClicked: player.playPrivateFM()
            }

            CategoryListItem {
                iconSource: "gfx/icon_background.png"
                title: "个性化推荐"
                subTitle: "根据你的口味生成，每天更新"

                Text {
                    anchors {
                        left: parent.left; top: parent.top; bottom: parent.bottom
                        margins: platformStyle.paddingLarge
                    }
                    width: height
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: platformStyle.fontSizeMedium
                    text: Qt.formatDateTime(new Date(), "dddd\nM.d")
                }

                onClicked: pageStack.push(Qt.resolvedUrl(user.loggedIn ? "RecommendPage.qml"
                                                                       : "LoginPage.qml"))
            }

            Item {
                width: parent.width
                height: platformStyle.graphicSizeLarge

                ListItemText {
                    anchors {
                        left: parent.left; leftMargin: platformStyle.paddingLarge
                        verticalCenter: parent.verticalCenter
                    }
                    text: "热门推荐"
                }
            }

            Grid {
                id: grid
                property int itemWidth: (width - spacing) / columns
                anchors {
                    left: parent.left; right: parent.right
                    margins: platformStyle.paddingLarge
                }
                spacing: platformStyle.paddingLarge
                columns: 2
                Repeater {
                    model: ListModel { id: hotSpotModel }
                    Item {
                        width: grid.itemWidth
                        height: width + platformStyle.graphicSizeLarge
                        Image {
                            id: coverImage
                            width: parent.width
                            height: parent.width
                            source: Api.getScaledImageUrl(picUrl, 160)
                            Loader {
                                anchors {
                                    left: parent.left; bottom: parent.bottom
                                    bottomMargin: platformStyle.paddingSmall
                                }
                                sourceComponent: type == 0 ? djProgramIcon : undefined
                                Component {
                                    id: djProgramIcon
                                    Image { source: "gfx/index_icn_dj.png" }
                                }
                            }
                        }
                        Text {
                            anchors { top: coverImage.bottom; topMargin: platformStyle.paddingMedium }
                            width: parent.width
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            font.pixelSize: platformStyle.fontSizeMedium
                            color: "white"
                            text: name
                        }
                        MouseArea {
                            anchors.fill: parent
                            onPressed: parent.opacity = 0.8
                            onReleased: parent.opacity = 1
                            onCanceled: parent.opacity = 1
                            onClicked: {
                                if (type == 0) {
                                    player.playDJ(id)
                                }
                                else if (type == 1) {
                                    pageStack.push(Qt.resolvedUrl("PlayListPage.qml"), { listId: id })
                                }
                            }
                        }
                    }
                }
            }
            Item {
                width: parent.width
                height: loading || hotSpotModel.count == 0 ? 200 : 0
                BusyIndicator {
                    anchors.centerIn: parent
                    running: loading
                    visible: loading
                }
                Button {
                    anchors.centerIn: parent
                    iconSource: privateStyle.toolBarIconPath("toolbar-refresh")
                    visible: !loading && hotSpotModel.count == 0
                    onClicked: getHotSpotList()
                }
            }
        }
    }

    ScrollDecorator { flickableItem: view }
}
