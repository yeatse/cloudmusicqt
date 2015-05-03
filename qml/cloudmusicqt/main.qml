import QtQuick 1.1
import com.nokia.symbian 1.1
import com.nokia.extras 1.1
import QtMobility.systeminfo 1.1
import com.yeatse.cloudmusic 1.0

import "../js/api.js" as Api

PageStackWindow {
    id: app

    focus: true
    platformSoftwareInputPanelEnabled: true

    initialPage: MainPage {
        id: mainPage
        tools: mainTools
    }

    QtObject {
        id: internal

        function initialize() {
            Api.qmlApi = qmlApi
            resetBackground()
            user.initialize()
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
    }

    Connections {
        target: qmlApi
        onProcessCommand: {
            console.log("qml api: process command", commandId)
            if (commandId == 1) {
                player.bringToFront()
            }
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
        volume: Math.min(deviceInfo.voiceRingtoneVolume, 50)
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

    ToolBarLayout {
        id: mainTools

        ToolButton {
            iconSource: "toolbar-back"
            onClicked: pageStack.depth <= 1 ? quitTimer.running ? Qt.quit() : quitTimer.start() : pageStack.pop()
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
            iconSource: "gfx/logo_icon.png"
            onClicked: player.bringToFront()
        }

        ToolButton {
            iconSource: "toolbar-settings"
            onClicked: infoBanner.showDevelopingMsg()
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
