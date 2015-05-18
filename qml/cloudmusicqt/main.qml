import QtQuick 1.1
import com.nokia.symbian 1.1
import com.nokia.extras 1.1
import QtMobility.systeminfo 1.1
import com.yeatse.cloudmusic 1.0

import "../js/api.js" as Api
import "../js/util.js" as Util

PageStackWindow {
    id: app

    focus: true
    platformSoftwareInputPanelEnabled: true

    initialPage: MainPage {}

    QtObject {
        id: internal

        function initialize() {
            Api.qmlApi = qmlApi
            resetBackground()
            user.initialize()
            checkForUpdate()
        }

        function resetBackground() {
            for (var i = 0; i < app.children.length; i++) {
                var child = app.children[i]
                if (child != volumeIndicator && child.hasOwnProperty("color")) {
                    child.z = -2
                    break
                }
            }
        }

        function checkForUpdate() {
            var xhr = new XMLHttpRequest
            xhr.onreadystatechange = function() {
                        if (xhr.readyState == XMLHttpRequest.DONE) {
                            if (xhr.status == 200) {
                                var resp = JSON.parse(xhr.responseText)
                                if (Util.verNameToVerCode(appVersion) < Util.verNameToVerCode(resp.ver)) {
                                    var diag = updateDialogComp.createObject(app)
                                    diag.message = "当前版本: %1\n最新版本: %2\n%3".arg(appVersion).arg(resp.ver).arg(resp.desc)
                                    diag.downUrl = resp.url
                                    diag.open()
                                }
                            }
                        }
                    }
            xhr.open("GET", "http://yeatse.com/cloudmusicqt/symbian.ver")
            xhr.send(null)
        }

        property Component updateDialogComp: Component {
            QueryDialog {
                id: dialog
                property bool closing: false
                property string downUrl
                titleText: "目测新版本粗现"
                acceptButtonText: "下载"
                rejectButtonText: "取消"
                onAccepted: Qt.openUrlExternally(downUrl)
                onStatusChanged: {
                    if (status == DialogStatus.Closing)
                        closing = true
                    else if (status == DialogStatus.Closed && closing)
                        dialog.destroy()
                }
            }
        }
    }

    Connections {
        target: qmlApi
        onProcessCommand: {
            console.log("qml api: process command", commandId)
            if (commandId == 1) {
                player.bringToFront()
            }
            else if (commandId == 2) {
                if (pageStack.currentPage == null
                        || pageStack.currentPage.objectName != player.callerTypeDownload)
                    pageStack.push(Qt.resolvedUrl("DownloadPage.qml"))
            }
        }
    }

    Connections {
        target: downloader
        onDownloadCompleted: {
            var msg = success ? "下载完成:" : "下载失败:"
            msg += musicName
            qmlApi.showNotification("网易云音乐", msg, 2)
        }
    }

    CloudMusicUser {
        id: user
    }

    DeviceInfo {
        id: deviceInfo
    }

    VolumeIndicator {
        id: volumeIndicator
        volume: Math.min(deviceInfo.voiceRingtoneVolume, 30)
    }

    InfoBanner {
        id: infoBanner

        function showMessage(msg) {
            infoBanner.text = msg
            infoBanner.open()
        }

        function showDevelopingMsg() {
            showMessage("此功能正在建设中...> <")
        }
    }

    PlayerPage {
        id: player
    }

    BlurredItem {
        id: background
        z: -1
        anchors.fill: parent
        source: backgroundImage.status == Image.Ready ? backgroundImage : null
        onHeightChanged: refresh()

        Image {
            id: backgroundImage
            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            source: player.currentMusic ? Api.getScaledImageUrl(player.currentMusic.albumImageUrl, 640)
                                        : ""
            visible: false
        }
    }

    Keys.onPressed: {
//        if (event.key == Qt.Key_Menu) qmlApi.takeScreenShot()
    }

    Keys.onVolumeUpPressed: volumeIndicator.volumeUp()
    Keys.onVolumeDownPressed: volumeIndicator.volumeDown()
    Keys.onUpPressed: volumeIndicator.volumeUp()
    Keys.onDownPressed: volumeIndicator.volumeDown()

    Component.onCompleted: internal.initialize()
}
