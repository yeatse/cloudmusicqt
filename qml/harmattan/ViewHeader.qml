import QtQuick 1.1
import "./UIConstants.js" as UI

Item {
    id: root

    property string title

    implicitWidth: ListView.view ? ListView.view.width : parent.width
    implicitHeight: UI.HEADER_DEFAULT_HEIGHT_PORTRAIT
    z: 1

    Image {
        id: icon
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: UI.PADDING_DOUBLE
        }
        source: "gfx/desk_logo.png"
    }

    Text {
        anchors {
            left: icon.right
            leftMargin: UI.PADDING_MEDIUM
            verticalCenter: parent.verticalCenter
        }
        font.pixelSize: UI.FONT_LARGE + 2
        color: "white"
        text: root.title
    }

    Rectangle {
        anchors {
            bottom: parent.bottom; left: parent.left; right: parent.right
            leftMargin: UI.PADDING_MEDIUM; rightMargin: UI.PADDING_MEDIUM
        }
        height: 1
        color: UI.COLOR_INVERTED_SECONDARY_FOREGROUND
    }
}
