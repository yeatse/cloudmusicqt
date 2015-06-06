import QtQuick 1.1
import com.nokia.symbian 1.1
import com.yeatse.cloudmusic 1.0

import "../js/util.js" as Util

Page {
    id: page

    property string startId
    property int defaultTab: MusicDownloadModel.ProcessingData
    onDefaultTabChanged: buttonRow.checkedButton = defaultTab == MusicDownloadModel.ProcessingData
                         ? toolButton1 : toolButton2

    orientationLock: PageOrientation.LockPortrait

    objectName: player.callerTypeDownload

    tools: ToolBarLayout {
        ToolButton {
            iconSource: "toolbar-back"
            onClicked: pageStack.pop()
        }
        ButtonRow {
            id: buttonRow
            ToolButton {
                id: toolButton1
                iconSource: "gfx/download.svg"
                onClicked: dlModel.dataType = MusicDownloadModel.ProcessingData
            }
            ToolButton {
                id: toolButton2
                iconSource: "gfx/ok.svg"
                onClicked: dlModel.dataType = MusicDownloadModel.CompletedData
            }
        }
        ToolButton {
            iconSource: "gfx/logo_icon.png"
            onClicked: player.bringToFront()
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        model: MusicDownloadModel {
            id: dlModel
            dataType: page.defaultTab
            onLoadFinished: {
                if (dataType == page.defaultTab && startId != "") {
                    var idx = getIndexByMusicId(startId)
                    if (idx > 0) listView.positionViewAtIndex(idx, ListView.Beginning)
                    startId = ""
                }
            }
        }
        header: ViewHeader {
            title: "我的下载"
            Button {
                id: ctrlBtn
                anchors {
                    right: parent.right; verticalCenter: parent.verticalCenter
                    rightMargin: platformStyle.paddingLarge
                }
                width: height
                iconSource: privateStyle.toolBarIconPath("toolbar-mediacontrol-play")
                enabled: listView.count > 0
                onClicked: player.playDownloader(dlModel, "")
                states: [
                    State {
                        name: "CanPause"
                        PropertyChanges {
                            target: ctrlBtn
                            iconSource: privateStyle.toolBarIconPath("toolbar-mediacontrol-pause")
                            onClicked: downloader.pause()
                        }
                    },
                    State {
                        name: "CanRestart"
                        PropertyChanges {
                            target: ctrlBtn
                            iconSource: privateStyle.toolBarIconPath("toolbar-refresh")
                            onClicked: {
                                downloader.resume()
                                downloader.retry()
                            }
                        }
                    }
                ]
                function reset() {
                    if (dlModel.dataType == MusicDownloadModel.CompletedData)
                        state = ""
                    else if (downloader.hasRunningTask())
                        state = "CanPause"
                    else
                        state = "CanRestart"
                }
                Connections {
                    target: dlModel
                    onDataTypeChanged: ctrlBtn.reset()
                    onLoadFinished: ctrlBtn.reset()
                }
            }
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
                contextMenu.itemStatus = status
                contextMenu.errcode = errcode
                contextMenu.musicId = id
                contextMenu.open()
            }
        }
    }

    ContextMenu {
        id: contextMenu

        property int itemStatus
        property int errcode
        property string musicId

        MenuLayout {
            MenuItem {
                text: "暂停"
                visible: contextMenu.itemStatus == 0 || contextMenu.itemStatus == 1
                onClicked: downloader.pause(contextMenu.musicId)
            }
            MenuItem {
                text: "继续"
                visible: contextMenu.itemStatus == 2
                onClicked: downloader.resume(contextMenu.musicId)
            }
            MenuItem {
                text: "播放"
                visible: contextMenu.itemStatus == 3
                onClicked: player.playDownloader(dlModel, contextMenu.musicId)
            }
            MenuItem {
                text: "删除"
                enabled: player.currentMusic == null || player.currentMusic.musicId != contextMenu.musicId
                onClicked: {
                    var file = Util.getLyricFromMusic(downloader.getDownloadFileName(contextMenu.musicId))
                    if (file != "")
                        qmlApi.removeFile(file)

                    if (contextMenu.itemStatus == 3 || (contextMenu.itemStatus == 4 && contextMenu.errcode == 4))
                        downloader.removeCompletedTask(contextMenu.musicId)
                    else
                        downloader.cancel(contextMenu.musicId)
                }
            }
            MenuItem {
                text: "重试"
                visible: contextMenu.itemStatus == 4
                onClicked: downloader.retry(contextMenu.musicId)
            }
        }
    }

    ScrollDecorator { flickableItem: listView }
}
