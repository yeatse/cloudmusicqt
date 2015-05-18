import QtQuick 1.1
import com.nokia.symbian 1.1

Page {
    id: page

    orientationLock: PageOrientation.LockPortrait

    tools: ToolBarLayout {
        ToolButton {
            iconSource: "toolbar-back"
            onClicked: pageStack.pop()
        }
    }

    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: app.inPortrait ? platformStyle.graphicSizeLarge : 0
        }
        spacing: platformStyle.paddingMedium

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            sourceSize.width: platformStyle.graphicSizeLarge * 2.5
            sourceSize.height: platformStyle.graphicSizeLarge * 2.5
            source: "gfx/cloudmusicqt.svg"
        }

        Label {
            font.pixelSize: platformStyle.fontSizeLarge + 4
            anchors.horizontalCenter: parent.horizontalCenter
            text: "网易云音乐测试版"
        }

        ListItemText {
            anchors.horizontalCenter: parent.horizontalCenter
            role: "SubTitle"
            text: "Version " + appVersion
        }
    }

    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom; bottomMargin: platformStyle.paddingMedium
        }
        visible: screen.height > 360
        ListItemText {
            role: "SubTitle"
            text: "Designed & built by Yeatse, 2015"
        }
    }
}
