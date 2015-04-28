import QtQuick 1.1
import com.nokia.symbian 1.1

Item {
    id: root

    property string title

    implicitWidth: screen.width
    implicitHeight: privateStyle.tabBarHeightPortrait
    z: 1

    Image {
        id: icon
        anchors {
            left: parent.left
            verticalCenter: parent.verticalCenter
            leftMargin: platformStyle.paddingLarge + platformStyle.paddingSmall
        }
        source: title == "" ? "gfx/desk2_logo.png" : "gfx/desk_logo.png"
    }

    Text {
        anchors {
            left: icon.right
            leftMargin: platformStyle.paddingMedium
            verticalCenter: parent.verticalCenter
        }
        font.pixelSize: platformStyle.fontSizeLarge + 2
        color: "white"
        text: root.title
    }

    Rectangle {
        anchors.bottom: parent.bottom
        width: parent.width
        height: 1
        color: platformStyle.colorDisabledMid
    }
}
