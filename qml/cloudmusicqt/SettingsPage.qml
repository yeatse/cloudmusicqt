import QtQuick 1.1
import com.nokia.symbian 1.1
import com.nokia.extras 1.1

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
                    var dir = qmlApi.selectFolder("选择文件夹:", downloader.targetDir)
                    if (dir) downloader.targetDir = dir
                }
            }
            SelectionListItem {
                title: "接入点设定"
                subTitle: "点击设置"
                onClicked: {
                    if (qmlApi.showAccessPointTip())
                        informDiagComp.createObject(page)
                    else
                        qmlApi.launchSettingApp()
                }

                Component {
                    id: informDiagComp
                    CommonDialog {
                        id: diag
                        property bool isClosing: false
                        titleText: "提示"
                        buttonTexts: ["确定"]
                        content: Item {
                            width: diag.platformContentMaximumWidth
                            height: contentCol.height + platformStyle.paddingLarge * 2
                            Column {
                                id: contentCol
                                anchors {
                                    left: parent.left; right: parent.right
                                    top: parent.top; margins: platformStyle.paddingLarge
                                }
                                spacing: platformStyle.paddingMedium
                                Label {
                                    width: parent.width
                                    wrapMode: Text.Wrap
                                    text: "由于Symbian系统的限制，在线流媒体的接入点需要单独设定。\n"
                                          +"请至系统设置→应用程序设置→视频下切换到合适的接入点。"
                                }
                                CheckBox {
                                    id: checkBox
                                    text: "以后不再提示"
                                }
                            }
                        }
                        onButtonClicked: {
                            if (checkBox.checked)
                                qmlApi.clearAccessPointTip()

                            qmlApi.launchSettingApp()
                        }
                        Component.onCompleted: open()
                        Component.onDestruction: app.forceActiveFocus()
                        onStatusChanged: {
                            if (status == DialogStatus.Closing)
                                isClosing = true
                            else if (status == DialogStatus.Closed && isClosing)
                                diag.destroy()
                        }
                    }
                }
            }
            SelectionListItem {
                title: "定时关闭"
                subTitle: cdTimer.active ? "程序将在%1分钟后关闭".arg(cdTimer.timeLeft)
                                         : "未启动"
                onClicked: cdDiagComp.createObject(page)
                Component {
                    id: cdDiagComp
                    TimePickerDialog {
                        id: diag
                        property bool isClosing: false
                        titleText: "设定程序关闭的时间"
                        acceptButtonText: "启动"
                        rejectButtonText: "关闭"
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
                        Component.onDestruction: app.forceActiveFocus()
                        onStatusChanged: {
                            if (status == DialogStatus.Closing)
                                isClosing = true
                            else if (status == DialogStatus.Closed && isClosing)
                                diag.destroy()
                        }
                    }
                }
            }
        }
    }
}
