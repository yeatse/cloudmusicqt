import QtQuick 1.1
import com.nokia.meego 1.0
import com.yeatse.cloudmusic 1.0

import "../js/util.js" as Util
import "./UIConstants.js" as UI

Page {
    id: page

    property string startId
    property int defaultTab: MusicDownloadModel.ProcessingData
    onDefaultTabChanged: buttonRow.checkedButton = defaultTab == MusicDownloadModel.ProcessingData
                         ? toolButton1 : toolButton2

    orientationLock: PageOrientation.LockPortrait

    objectName: player.callerTypeDownload

    tools: ToolBarLayout {
        ToolIcon {
            platformIconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
        ButtonRow {
            id: buttonRow
            TabButton {
                id: toolButton1
                iconSource: "gfx/download.svg"
                onClicked: dlModel.dataType = MusicDownloadModel.ProcessingData
            }
            TabButton {
                id: toolButton2
                iconSource: "gfx/ok.svg"
                onClicked: dlModel.dataType = MusicDownloadModel.CompletedData
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
            implicitWidth: app.inPortrait ? screen.displayHeight : screen.displayWidth
            Button {
                id: ctrlBtn
                anchors {
                    right: parent.right; verticalCenter: parent.verticalCenter
                    rightMargin: UI.PADDING_LARGE
                }
                platformStyle: ButtonStyle {
                    buttonWidth: buttonHeight
                }
                iconSource: "image://theme/icon-m-toolbar-mediacontrol-play-white"
                enabled: listView.count > 0
                onClicked: player.playDownloader(dlModel, "")
                states: [
                    State {
                        name: "CanPause"
                        PropertyChanges {
                            target: ctrlBtn
                            iconSource: "image://theme/icon-m-toolbar-mediacontrol-pause-white"
                            onClicked: downloader.pause()
                        }
                    },
                    State {
                        name: "CanRestart"
                        PropertyChanges {
                            target: ctrlBtn
                            iconSource: "image://theme/icon-m-toolbar-redo-white"
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
                Component.onCompleted: reset()
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
            onClicked: contextDialog.init(name, status, errcode, id)
        }
    }

    SelectionDialog {
        id: contextDialog

        property int itemStatus
        property int errcode
        property string musicId

        selectedIndex: -1

        function init(name, stat, err, mid) {
            titleText = name
            itemStatus = stat
            errcode = err
            musicId = mid

            var item1
            if (itemStatus == 2)
                item1 = "继续"
            else if (itemStatus == 3)
                item1 = "播放"
            else if (itemStatus == 4)
                item1 = "重试"
            else
                item1 = "暂停"

            model.clear()
            model.append({name: item1})
            model.append({name: "删除"})
            selectedIndex = 0

            open()
        }

        onAccepted: {
            if (selectedIndex == 0) {
                if (itemStatus == 2)
                    downloader.resume(musicId)
                else if (itemStatus == 3)
                    player.playDownloader(dlModel, musicId)
                else if (itemStatus == 4)
                    downloader.retry(musicId)
                else
                    downloader.pause(musicId)
            }
            else if (selectedIndex == 1) {
                if (player.currentMusic == null || player.currentMusic.musicId != musicId) {
                    var file = Util.getLyricFromMusic(downloader.getDownloadFileName(musicId))
                    if (file != "")
                        qmlApi.removeFile(file)

                    if (itemStatus == 3 || (itemStatus == 4 && errcode == 4))
                        downloader.removeCompletedTask(musicId)
                    else
                        downloader.cancel(musicId)
                }
                else {
                    infoBanner.showMessage("无法删除正在播放的歌曲");
                }
            }
        }
    }

    ScrollDecorator { flickableItem: listView }
}
