import QtQuick 1.1
import "./UIConstants.js" as UI

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
        width: UI.LIST_ITEM_HEIGHT_SMALL
        height: parent.height
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: UI.FONT_LARGE
        color: UI.COLOR_INVERTED_SECONDARY_FOREGROUND
        text: index + 1
        visible: showIndex
    }

    Column {
        anchors {
            left: showIndex ? indexText.right : parent.left;
            leftMargin: showIndex ? 0 : UI.PADDING_LARGE
            right: parent.right
            verticalCenter: parent.verticalCenter
        }
        spacing: UI.PADDING_SMALL

        Text {
            id: titleText
            width: parent.width
            font.pixelSize: UI.FONT_LARGE
            color: UI.COLOR_INVERTED_FOREGROUND
            elide: Text.ElideRight
        }

        Text {
            id: subTitleText
            width: parent.width
            font.pixelSize: UI.FONT_SMALL
            color: UI.COLOR_INVERTED_SECONDARY_FOREGROUND
            elide: Text.ElideRight
        }
    }
}
