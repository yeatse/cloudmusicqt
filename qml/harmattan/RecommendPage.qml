import QtQuick 1.1
import com.nokia.meego 1.0
import com.yeatse.cloudmusic 1.0

import "../js/api.js" as Api
import "./UIConstants.js" as UI

Page {
    id: page

    property bool loading: false

    orientationLock: PageOrientation.LockPortrait

    tools: ToolBarLayout {
        ToolIcon {
            platformIconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
        ToolIcon {
            platformIconId: "toolbar-refresh"
            enabled: !loading
            onClicked: getRecommendList()
        }
        ToolIcon {
            iconSource: "gfx/logo_icon.png"
            onClicked: player.bringToFront()
        }
    }

    function getRecommendList() {
        if (loading) return
        var s = function(resp) {
            loading = false
            listModel.clear()
            for (var i in resp.recommend)
                listModel.append(resp.recommend[i])
        }
        var f = function(err) {
            loading = false
            console.log("get recommend failed: ", err)
        }
        loading = true
        Api.getRecommendResource(s, f)
    }

    ListView {
        id: listView
        anchors.fill: parent
        model: ListModel { id: listModel }
        header: Column {
            width: ListView.view.width
            ViewHeader {
                title: "个性化推荐"
            }
            CategoryListItem {
                iconSource: "gfx/icon_background.png"
                title: "每日歌曲推荐"
                subTitle: "根据你的音乐口味生成，每天更新"

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

                onClicked: pageStack.push(Qt.resolvedUrl("DailyRecommendPage.qml"))
            }
        }
        delegate: CategoryListItem {
            title: name
            subTitle: copywriter
            iconSource: Api.getScaledImageUrl(picUrl, 80)
            onClicked: {
                var prop = { listId: id }
                pageStack.push(Qt.resolvedUrl("PlayListPage.qml"), prop)
            }
        }
        footer: Item {
            width: listView.width
            height: loading ? 200 : 0
            BusyIndicator {
                anchors.centerIn: parent
                running: loading
                visible: loading
            }
        }
    }

    Component.onCompleted: getRecommendList()
}
