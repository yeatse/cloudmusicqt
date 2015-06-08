import QtQuick 1.1
import com.nokia.meego 1.0

import "../js/api.js" as Api
import "UIConstants.js" as UI

Page {
    id: page

    property string commentId
    property bool requestLoad: true
    property bool loading: false
    property bool hasMore: false

    property int hotCount: 0
    property int totalCount: 0
    property int offset: 0

    orientationLock: PageOrientation.LockPortrait

    onStatusChanged: {
        if (status == PageStatus.Active && requestLoad) {
            requestLoad = false
            loadCommentList()
        }
    }

    function loadCommentList(option) {
        if (loading) return
        option = option || "refresh"
        var opt = { rid: commentId }
        if (option == "refresh") {
            opt.offset = offset = 0
            opt.total = true
        }
        else if (option == "next") {
            opt.offset = offset
            opt.total = false
        }
        var s = function (resp) {
            loading = false
            hasMore = resp.more
            totalCount = resp.total
            offset = opt.offset + resp.comments.length

            if (option == "refresh")
                listModel.clear()

            var parse = function(data, type) {
                var prop = {
                    type: type,
                    avatar: Api.getScaledImageUrl(data.user.avatarUrl, 50),
                    content: data.user.nickname + ": " + data.content,
                    time: Qt.formatDateTime(new Date(Number(data.time)), "yyyy-MM-dd hh:mm:ss"),
                    refContent: ""
                }
                if (data.beReplied.length > 0) {
                    prop.refContent = data.beReplied[0].user.nickname
                            + ": " + data.beReplied[0].content
                }
                listModel.append(prop)
            }

            if (Array.isArray(resp.hotComments)) {
                hotCount = resp.hotComments.length
                for (var i in resp.hotComments) {
                    parse(resp.hotComments[i], 1)
                }
            }

            for (var i in resp.comments)
                parse(resp.comments[i], 0)
        }
        var f = function(err) {
            loading = false
            console.log("load comment failed:", err)
        }
        loading = true
        Api.getCommentList(opt, s, f)
    }

    tools: ToolBarLayout {
        ToolIcon {
            platformIconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
    }

    ListView {
        id: view
        property Item footerItem: null
        anchors.fill: parent
        cacheBuffer: 200
        model: ListModel { id: listModel }
        header: ViewHeader {
            title: "评论"
        }
        section {
            property: "type"
            delegate: ListHeading {
                ListItemText {
                    anchors.fill: parent.paddingItem
                    role: "Heading"
                    text: section == 0 ? "最新评论(%1)".arg(page.totalCount)
                                       : "热门评论(%1)".arg(page.hotCount)
                }
            }
        }
        delegate: ListItemFrame {
            implicitHeight: contentCol.height + UI.PADDING_XLARGE

            Image {
                id: avatarImg
                anchors {
                    left: parent.left; top: parent.top;
                    margins: UI.PADDING_LARGE
                }
                width: UI.LIST_ITEM_HEIGHT_SMALL
                height: UI.LIST_ITEM_HEIGHT_SMALL
                sourceSize { width: width; height: height }
                source: avatar
            }

            Column {
                id: contentCol
                anchors {
                    left: avatarImg.right; leftMargin: UI.PADDING_MEDIUM
                    top: parent.top; topMargin: UI.PADDING_LARGE
                    right: parent.right; rightMargin: UI.PADDING_LARGE
                }
                spacing: UI.PADDING_MEDIUM

                Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: content
                }

                Loader {
                    sourceComponent: refContent ? refComp : undefined
                    Component {
                        id: refComp
                        Rectangle {
                            width: contentCol.width
                            height: refLabel.height + UI.PADDING_XLARGE
                            color: "#803a3a3a"
                            border.width: 1
                            border.color: "#801f1f1f"
                            Label {
                                id: refLabel
                                anchors {
                                    left: parent.left; top: parent.top
                                    right: parent.right; margins: UI.PADDING_LARGE
                                }
                                wrapMode: Text.Wrap
                                text: refContent
                            }
                        }
                    }
                }

                Label {
                    platformStyle: LabelStyle {
                        fontPixelSize: UI.FONT_SMALL
                        textColor: UI.COLOR_INVERTED_SECONDARY_FOREGROUND
                    }
                    text: time
                }
            }
        }
        footer: Item {
            id: footerItem
            width: ListView.view.width
            height: visible ? UI.LIST_ITEM_HEIGHT_DEFAULT : 0
            visible: page.hasMore && listModel.count > 0
            BusyIndicator {
                anchors.centerIn: parent
                running: !view.moving && page.loading
            }
            Component.onCompleted: view.footerItem = footerItem
        }

        onMovementEnded: {
            if (footerItem != null && !page.loading && page.hasMore &&
                    footerItem.mapToItem(view, 0, 0).y < view.height)
            {
                page.loadCommentList("next")
            }
        }
    }

    ScrollDecorator { flickableItem: view }

    BusyIndicator {
        platformStyle: BusyIndicatorStyle { size: "large" }
        anchors.centerIn: parent
        visible: page.loading && listModel.count == 0
        running: visible
    }
}
