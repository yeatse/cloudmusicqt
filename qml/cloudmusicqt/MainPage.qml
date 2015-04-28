import QtQuick 1.1
import com.nokia.symbian 1.1

Page {
    id: mainPage

    orientationLock: PageOrientation.LockPortrait

    Flickable {
        id: view
        anchors.fill: parent
        contentWidth: parent.width
        contentHeight: contentColumn.height

        Column {
            id: contentColumn
            width: parent.width

            ViewHeader {
                id: viewHeader
                ToolButton {
                    anchors {
                        right: parent.right
                        verticalCenter: parent.verticalCenter
                    }
                    iconSource: "gfx/contacts.svg"
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("LoginPage.qml"))
                    }
                }
            }

            CategoryItem {
                iconSource: "gfx/private_radio_icon.png"
                title: "私人FM"
                subTitle: "放松下来，享受你的专属推荐"
            }

            CategoryItem {
                iconSource: "gfx/private_radio_icon.png"
                title: "个性化推荐"
                subTitle: "根据你的口味生成，每天更新"
            }
        }
    }
}
