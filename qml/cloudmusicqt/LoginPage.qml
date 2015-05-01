import QtQuick 1.1
import com.nokia.symbian 1.1
import QtWebKit 1.0
import "../js/api.js" as Api

Page {
    id: page

    orientationLock: PageOrientation.LockPortrait

    tools: ToolBarLayout {
        ToolButton {
            iconSource: "toolbar-back"
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
            url: Api.CloundMusicApi.SNS_AUTH_SINA

            javaScriptWindowObjects: QtObject {
                WebView.windowObjectName: "top"

                function postMessage(msg) {
                    console.log(JSON.stringify(msg))
                }
            }

            Component.onDestruction: app.forceActiveFocus()
        }
    }

    ProgressBar {
        anchors.bottom: parent.bottom
        width: parent.width
        value: webView.progress
        visible: webView.status == WebView.Loading
    }
}
