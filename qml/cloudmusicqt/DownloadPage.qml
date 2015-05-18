import QtQuick 1.1
import com.nokia.symbian 1.1
import com.yeatse.cloudmusic 1.0

Page {
    id: page

    orientationLock: PageOrientation.LockPortrait

    objectName: player.callerTypeDownload

    tools: ToolBarLayout {
        ToolButton {
            iconSource: "toolbar-back"
            onClicked: pageStack.pop()
        }
        ToolButton {
            iconSource: "toolbar-mediacontrol-play"
            enabled: listView.count > 0
            onClicked: player.playDownloader(0)
        }
        ToolButton {
            iconSource: "gfx/logo_icon.png"
            onClicked: player.bringToFront()
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
            active: player.currentMusic != null && player.currentMusic.musicId == id
            title: artist + " - " + name
            subTitle: {
                switch (status) {
                case 0: return "等待下载"
                case 1: return "正在下载: %1%".arg(Math.round(progress * 100 / size))
                case 2: return "下载暂停"
                case 3: return "下载完成"
                case 4: return errcode == 4 ? "文件已删除" : "下载失败, 代码: %1".arg(errcode)
                default: return ""
                }
            }
            onClicked: {
                contextMenu.mIndex = index
                contextMenu.mStatus = status
                contextMenu.musicId = id
                contextMenu.open()
            }
        }
    }

    ContextMenu {
        id: contextMenu

        property int mIndex
        property int mStatus
        property string musicId

        MenuLayout {
            MenuItem {
                text: "暂停"
                visible: contextMenu.mStatus == 0 || contextMenu.mStatus == 1
                onClicked: downloader.pause(contextMenu.musicId)
            }
            MenuItem {
                text: "继续"
                visible: contextMenu.mStatus == 2
                onClicked: downloader.resume(contextMenu.musicId)
            }
            MenuItem {
                text: "播放"
                visible: contextMenu.mStatus == 3
                onClicked: player.playDownloader(contextMenu.mIndex)
            }
            MenuItem {
                text: "删除"
                enabled: player.currentMusic == null || player.currentMusic.musicId != contextMenu.musicId
                onClicked: {
                    if (contextMenu.mStatus == 3)
                        downloader.removeCompletedTask(contextMenu.musicId)
                    else
                        downloader.cancel(contextMenu.musicId)
                }
            }
            MenuItem {
                text: "重试"
                visible: contextMenu.mStatus == 4
                onClicked: downloader.retry(contextMenu.musicId)
            }
        }

        onStatusChanged: {
            if (status == DialogStatus.Closed)
                app.focus = true
        }
    }

    ScrollDecorator { flickableItem: listView }
}
