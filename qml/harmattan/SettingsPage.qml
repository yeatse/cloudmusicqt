import QtQuick 1.1
import com.nokia.meego 1.0
import com.nokia.extras 1.1

Page {
    id: page

    tools: ToolBarLayout {
        ToolIcon {
            platformIconId: "toolbar-back"
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
            ListDelegate {
                property QtObject model: QtObject {
                    property string title: "下载目录"
                    property string subtitle: downloader.targetDir
                }
                onClicked: {
                    var dir = qmlApi.selectFolder("选择文件夹:", downloader.targetDir)
                    if (dir) downloader.targetDir = dir
                }
            }
            ListDelegate {
                property QtObject model: QtObject {
                    property string title: "定时关闭"
                    property string subtitle: cdTimer.active ? "程序将在%1分钟后关闭".arg(cdTimer.timeLeft)
                                                             : "未启动"
                }
                onClicked: cdDiagComp.createObject(page)
                Component {
                    id: cdDiagComp
                    TimePickerDialog {
                        id: diag
                        property bool isClosing: false
                        titleText: "设定程序关闭的时间"
                        acceptButtonText: "启动"
                        rejectButtonText: "关闭"
                        fields: DateTime.Hours | DateTime.Minutes
                        Component.onCompleted: {
                            cdTimer.active = false
                            hour = Math.floor(cdTimer.timeLeft / 60)
                            minute = cdTimer.timeLeft % 60
                            open()
                        }
                        onAccepted: {
                            var result = hour * 60 + minute
                            if (result > 0) {
                                cdTimer.timeLeft = result
                                cdTimer.active = true
                            }
                        }
                        onStatusChanged: {
                            if (status == DialogStatus.Closing)
                                isClosing = true
                            else if (status == DialogStatus.Closed && isClosing)
                                diag.destroy(500)
                        }
                    }
                }
            }
        }
    }
}
