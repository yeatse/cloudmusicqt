import QtQuick 1.1
import com.nokia.meego 1.0
import com.yeatse.cloudmusic 1.0

import "../js/api.js" as Api
import "./UIConstants.js" as UI

Page {
    id: mainPage

    orientationLock: PageOrientation.LockPortrait

    property bool loading: false
    property variant searchPageComp: null

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
        ToolIcon {
            platformIconId: "toolbar-search"
            onClicked: {
                searchPageComp = searchPageComp || Qt.createComponent("SearchPage.qml");
                searchPageComp.createObject(mainPage);
            }
        }
        ToolIcon {
            platformIconId: "toolbar-view-menu"
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
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: "关于"
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
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
                title: "网易云音乐"
                Button {
                    anchors {
                        right: parent.right; rightMargin: UI.PADDING_LARGE
                        verticalCenter: parent.verticalCenter
                    }
                    platformStyle: ButtonStyle { buttonWidth: buttonHeight }
                    iconSource: "image://theme/icon-m-toolbar-contact-white"
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
                        margins: UI.PADDING_LARGE
                    }
                    width: height
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: UI.FONT_DEFAULT
                    text: Qt.formatDateTime(new Date(), "dddd\nM.d")
                }

                onClicked: pageStack.push(Qt.resolvedUrl(user.loggedIn ? "RecommendPage.qml"
                                                                       : "LoginPage.qml"))
            }

            Item {
                width: parent.width
                height: UI.LIST_ITEM_HEIGHT_DEFAULT

                Label {
                    anchors {
                        left: parent.left; leftMargin: UI.PADDING_LARGE
                        verticalCenter: parent.verticalCenter
                    }
                    platformStyle: LabelStyle {
                        fontPixelSize: UI.FONT_LARGE
                    }
                    text: "热门推荐"
                }
            }

            Grid {
                id: grid
                property int itemWidth: (width - spacing) / columns
                anchors {
                    left: parent.left; right: parent.right
                    margins: UI.PADDING_LARGE
                }
                spacing: UI.PADDING_LARGE
                columns: 2
                Repeater {
                    model: ListModel { id: hotSpotModel }
                    Item {
                        width: grid.itemWidth
                        height: width + UI.LIST_ITEM_HEIGHT_DEFAULT
                        Image {
                            id: coverImage
                            width: parent.width
                            height: parent.width
                            source: Api.getScaledImageUrl(picUrl, 240)
                            Loader {
                                anchors {
                                    left: parent.left; bottom: parent.bottom
                                    bottomMargin: UI.PADDING_SMALL
                                }
                                sourceComponent: type == 0 ? djProgramIcon : undefined
                                Component {
                                    id: djProgramIcon
                                    Image { source: "gfx/index_icn_dj.png" }
                                }
                            }
                        }
                        Text {
                            anchors { top: coverImage.bottom; topMargin: UI.PADDING_MEDIUM }
                            width: parent.width
                            elide: Text.ElideRight
                            wrapMode: Text.Wrap
                            maximumLineCount: 2
                            font.pixelSize: UI.FONT_DEFAULT
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
                    platformStyle: ButtonStyle { buttonWidth: buttonHeight }
                    iconSource: "image://theme/icon-m-toolbar-refresh-white"
                    visible: !loading && hotSpotModel.count == 0
                    onClicked: getHotSpotList()
                }
            }
        }
    }

    ScrollDecorator { flickableItem: view }
}
