import QtQuick 1.1
import com.nokia.meego 1.0
import QtWebKit 1.0
import "../js/api.js" as Api

Page {
    id: page

    orientationLock: PageOrientation.LockPortrait

    tools: ToolBarLayout {
        ToolIcon {
            platformIconId: "toolbar-back"
            onClicked: pageStack.pop()
        }
    }

    ViewHeader {
        id: viewHeader
        title: "登录"
    }

    Flickable {
        id: flickable
        anchors { fill: parent; topMargin: viewHeader.height }
        contentWidth: webView.width
        contentHeight: webView.height
        boundsBehavior: Flickable.DragOverBounds
        WebView {
            id: webView
            contentsScale: 1.1
            preferredWidth: flickable.width / contentsScale
            preferredHeight: flickable.height / contentsScale
            url: Api.CloudMusicApi.SNS_AUTH_SINA

            javaScriptWindowObjects: QtObject {
                WebView.windowObjectName: "top"

                function postMessage(msg) {
                    if (msg.code == 200 && msg.callbackType == "Login") {
                        qmlApi.saveUserId(msg.account.id)
                        user.initialize()
                        pageStack.pop()
                    }
                }
            }

            onStatusChanged: {
                console.log(status)
            }
        }
    }

    ProgressBar {
        anchors.bottom: parent.bottom
        width: parent.width
        value: webView.progress
        visible: webView.status == WebView.Loading
    }
}
