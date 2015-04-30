import QtQuick 1.1
import com.nokia.symbian 1.1
import com.nokia.extras 1.1
import QtMobility.systeminfo 1.1

PageStackWindow {
    id: app

    focus: true

    platformSoftwareInputPanelEnabled: true

    initialPage: MainPage {
        id: mainPage
        tools: mainTools
    }

    PlayerPage {
        id: playerPage
    }

    function showMessage(msg) {
        infoBanner.text = msg
        infoBanner.open()
    }

    QtObject {
        id: internal

        function resetBackground() {
            var bgColor = "#313131"
            if (app.hasOwnProperty("color")) {
                app.color = bgColor
            }
            else {
                for (var i = app.children.length - 1; i >= 0; i--) {
                    var child = app.children[i]
                    if (child != volumeIndicator && child.hasOwnProperty("color")) {
                        child.color = bgColor
                        break
                    }
                }
            }
        }
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
        }

        ToolButton {
            iconSource: "toolbar-settings"
        }
    }

    Keys.onVolumeUpPressed: volumeIndicator.volumeUp()
    Keys.onVolumeDownPressed: volumeIndicator.volumeDown()
    Keys.onUpPressed: volumeIndicator.volumeUp()
    Keys.onDownPressed: volumeIndicator.volumeDown()

    Component.onCompleted: internal.resetBackground()
}
