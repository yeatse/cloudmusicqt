import QtQuick 1.1
import com.nokia.symbian 1.1

Page {
    id: page

    tools: ToolBarLayout {
        ToolButton {
            iconSource: "toolbar-back"
            onClicked: pageStack.pop()
        }
    }

    orientationLock: PageOrientation.LockPortrait

    Flickable {
        id: flickable
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: contentCol.height

        Column {
            id: contentCol
            width: parent.width
            ViewHeader {
                title: "设置"
            }
            SelectionListItem {
                title: "下载目录"
                subTitle: downloader.targetDir
                onClicked: {
                    var dir = qmlApi.selectFolder("选择下载文件夹:", downloader.targetDir)
                    if (dir) downloader.targetDir = dir
                }
            }
        }
    }
}
