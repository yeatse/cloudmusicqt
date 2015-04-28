import QtQuick 1.1
import com.nokia.symbian 1.1
import QtWebKit 1.0

Page {
    id: page

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

    WebView {
        id: webView
        anchors { fill: parent; topMargin: viewHeader.height }
        contentsScale: 1.2
        preferredWidth: parent.width / contentsScale
        preferredHeight: parent.height / contentsScale
        url: "http://www.baidu.com"


        Component.onDestruction: app.forceActiveFocus()
    }
}
