import QtQuick 1.1
import com.nokia.symbian 1.1
import com.yeatse.cloudmusic 1.0

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
                    onClicked: pageStack.push(Qt.resolvedUrl( user.loggedIn ? "LoginPage.qml" : "LoginPage.qml" ))
                }
            }

            CategoryItem {
                iconSource: "gfx/private_radio_icon.png"
                title: "私人FM"
                subTitle: "放松下来，享受你的专属推荐"
                onClicked: player.playPrivateFM()
            }

            CategoryItem {
                iconSource: "gfx/icon_background.png"
                title: "个性化推荐"
                subTitle: "根据你的口味生成，每天更新"

                Text {
                    anchors {
                        left: parent.left; top: parent.top; bottom: parent.bottom
                        margins: platformStyle.paddingLarge
                    }
                    width: height
                    color: "white"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: platformStyle.fontSizeSmall - 2
                    text: Qt.formatDateTime(new Date(), "dddd\nM.d")
                }

                onClicked: pageStack.push(Qt.resolvedUrl("RecommendPage.qml"))
            }
        }
    }
}
