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
    }

    ListView {
        id: listView
        anchors.fill: parent
        model: MusicDownloadModel { id: dlModel }
        header: ViewHeader {
            title: "我的下载"
        }
        delegate: MusicListItem {
            title: artist + " - " + name
            subTitle: {
                switch (status) {
                case 0: return "等待下载"
                case 1: return "正在下载: %1%".arg(Math.round(progress * 100 / size))
                case 2: return "下载暂停"
                case 3: return "下载完成"
                case 4: return "下载失败, 代码: %1".arg(errcode)
                default: return ""
                }
            }
        }
    }

    ContextMenu {
        id: contextMenu
        MenuLayout {
            MenuItem {
                text: "暂停"
            }
        }
    }

    ScrollDecorator { flickableItem: listView }
}
