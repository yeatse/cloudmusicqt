import QtQuick 1.1
import com.nokia.symbian 1.1
import com.nokia.extras 1.1
import QtMobility.systeminfo 1.1
import com.yeatse.cloudmusic 1.0

PageStackWindow {
    id: app

    focus: true
    platformSoftwareInputPanelEnabled: true

    initialPage: MainPage {
        id: mainPage
        tools: mainTools
    }

    function showMessage(msg) {
        infoBanner.text = msg
        infoBanner.open()
    }

    QtObject {
        id: internal

        function initialize() {
            resetBackground()
            user.initialize()
        }

        function resetBackground() {
            var bgColor = "#313131"
            if (app.hasOwnProperty("color")) {
                app.color = bgColor
            }
            else {
                for (var i = app.children.length - 1; i >= 0; i--) {
                    var child = app.children[i]
                    if (child != volumeIndicator && child.hasOwnProperty("color")) {
                        child.z = -2
                        child.color = bgColor
                        break
                    }
                }
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
    }

    ToolBarLayout {
        id: mainTools

        ToolButton {
            iconSource: "toolbar-back"
            onClicked: pageStack.depth <= 1 ? quitTimer.running ? Qt.quit() : quitTimer.start() : pageStack.pop()
            Timer {
                id: quitTimer
                interval: infoBanner.timeout
                onRunningChanged: if (running) showMessage("再按一次退出")
            }
        }

        ToolButton {
            iconSource: "toolbar-search"
            onClicked: qmlApi.takeScreenShot()
        }

        ToolButton {
            iconSource: "toolbar-mediacontrol-play"
            onClicked: player.bringToFront()
        }

        ToolButton {
            iconSource: "toolbar-settings"
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

        Image {
            id: backgroundImage
            anchors.fill: parent
            asynchronous: true
            fillMode: Image.PreserveAspectCrop
            source: player.currentMusic ? player.currentMusic.albumImageUrl : ""
            visible: false
        }
    }

    Keys.onVolumeUpPressed: volumeIndicator.volumeUp()
    Keys.onVolumeDownPressed: volumeIndicator.volumeDown()
    Keys.onUpPressed: volumeIndicator.volumeUp()
    Keys.onDownPressed: volumeIndicator.volumeDown()

    Component.onCompleted: internal.initialize()
}
