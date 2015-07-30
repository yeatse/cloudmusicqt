import QtQuick 1.1
import com.nokia.meego 1.0
import "./UIConstants.js" as UI

Page {
    id: page

    orientationLock: PageOrientation.LockPortrait

    tools: ToolBarLayout {
        ToolIcon {
            platformIconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
    }

    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            top: parent.top
            topMargin: UI.LIST_ITEM_HEIGHT_SMALL
        }
        spacing: UI.PADDING_MEDIUM

        Image {
            anchors.horizontalCenter: parent.horizontalCenter
            sourceSize.width: UI.LIST_ITEM_HEIGHT_DEFAULT * 2.5
            sourceSize.height: UI.LIST_ITEM_HEIGHT_DEFAULT * 2.5
            source: "gfx/cloudmusicqt.svg"
        }

        Label {
            platformStyle: LabelStyle { fontPixelSize: UI.FONT_XLARGE }
            anchors.horizontalCenter: parent.horizontalCenter
            text: "网易云音乐测试版"
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            platformStyle: LabelStyle {
                fontPixelSize: UI.FONT_SMALL
                textColor: UI.COLOR_INVERTED_SECONDARY_FOREGROUND
            }
            text: "Version " + appVersion
        }
    }

    Column {
        anchors {
            horizontalCenter: parent.horizontalCenter
            bottom: parent.bottom; bottomMargin: UI.PADDING_MEDIUM
        }
        visible: app.inPortrait
        Label {
            platformStyle: LabelStyle {
                fontPixelSize: UI.FONT_SMALL
                textColor: UI.COLOR_INVERTED_SECONDARY_FOREGROUND
            }
            text: "Designed & built by Yeatse, 2015"
        }
    }
}
