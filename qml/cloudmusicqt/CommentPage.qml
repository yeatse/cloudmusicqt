import QtQuick 1.1
import com.nokia.symbian 1.1

import "../js/api.js" as Api

Page {
    id: page

    property string commentId
    property bool requestLoad: true
    property bool loading: false
    property bool hasMore: false

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
            offset = resp.comments.length

            if (option == "refresh")
                listModel.clear()

            var parse = function(data, type) {
                var prop = {
                    type: type,
                    avatar: data.user.avatarUrl,
                    content: data.user.nickname + ": " + qmlApi.processContent(data.content),
                    time: Qt.formatDateTime(new Date(data.time), "yyyy-MM-dd hh:mm:ss"),
                    refContent: ""
                }
                if (data.beReplied) {
                    prop.refContent = data.beReplied.user.nickname
                            + ": " + qmlApi.processContent(data.beReplied.content)
                }
                listModel.append(prop)
            }

            if (Array.isArray(resp.hotComments)) {
                for (var i in resp.hotComments) {
                    parse(resp.hotComments[i], 1)
                }
            }

            for (var i in resp.comments)
                parse(resp.comments[i], 0)
        }
    }

    tools: ToolBarLayout {
        ToolButton {
            iconSource: "toolbar-back"
        }
    }

    ListView {
        id: view
        anchors.fill: parent
        model: ListModel { id: listModel }
        header: ViewHeader {
            title: "评论(%1)".arg(totalCount)
        }
        delegate: ListItemFrame {

        }
    }
}
