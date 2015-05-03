import QtQuick 1.1
import com.nokia.symbian 1.1

ListItemFrame {
    id: root

    property bool active: false
    property bool showIndex: false
    property alias title: titleText.text
    property alias subTitle: subTitleText.text

    Loader {
        id: indicatorLoader
        sourceComponent: active ? indicatorComponent : undefined
        Component {
            id: indicatorComponent
            Image {
                height: root.height
                sourceSize.height: height
                fillMode: Image.PreserveAspectFit
                source: "gfx/qtg_graf_unread_indicator.svg"
            }
        }
    }

    Text {
        id: indexText
        width: platformStyle.graphicSizeMedium
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: platformStyle.fontSizeLarge
        color: platformStyle.colorNormalMid
        text: index + 1
        visible: showIndex
    }

    Column {
        anchors {
            left: showIndex ? indexText.right : parent.left;
            leftMargin: showIndex ? 0 : platformStyle.paddingLarge
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: platformStyle.paddingSmall

        Text {
            id: titleText
            width: parent.width
            font.pixelSize: platformStyle.fontSizeLarge
            color: platformStyle.colorNormalLight
            elide: Text.ElideRight
        }

        Text {
            id: subTitleText
            width: parent.width
            font.pixelSize: platformStyle.fontSizeSmall
            color: platformStyle.colorNormalMid
            elide: Text.ElideRight
        }
    }
}
