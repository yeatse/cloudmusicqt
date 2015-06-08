import QtQuick 1.1
import "UIConstants.js" as UI

ListItemFrame {
    id: root

    property alias iconSource: icon.source
    property alias title: titleText.text
    property alias subTitle: subTitleText.text

    implicitHeight: UI.LIST_ITEM_HEIGHT_DEFAULT + UI.PADDING_LARGE

    Image {
        id: icon
        anchors {
            left: parent.left; top: parent.top; bottom: parent.bottom
            margins: UI.PADDING_LARGE
        }
        width: height
        sourceSize { width: width; height: height }
    }

    Column {
        anchors {
            left: icon.right; leftMargin: UI.PADDING_MEDIUM
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
