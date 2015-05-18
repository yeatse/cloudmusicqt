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
        ToolButton {
            iconSource: "gfx/logo_icon.png"
            onClicked: player.bringToFront()
        }
    }

    Flickable {
        id: view
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight:  contentColumn.height

        Column {
            id: contentColumn
            width: parent.width

            ViewHeader {
                id: viewHeader
                title: "更多"
            }

            ListItemFrame {
                ListItemText {
                    anchors {
                        left: parent.left; leftMargin: platformStyle.paddingLarge
                        verticalCenter: parent.verticalCenter
                    }
                    text: "下载管理"
                }
                onClicked: pageStack.push(Qt.resolvedUrl("DownloadPage.qml"))
            }

            ListItemFrame {
                ListItemText {
                    anchors {
                        left: parent.left; leftMargin: platformStyle.paddingLarge
                        verticalCenter: parent.verticalCenter
                    }
                    text: "一般设定"
                }
            }

            ListItemFrame {
                ListItemText {
                    anchors {
                        left: parent.left; leftMargin: platformStyle.paddingLarge
                        verticalCenter: parent.verticalCenter
                    }
                    text: "关于"
                }
            }
        }
    }
}
