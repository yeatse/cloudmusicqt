import QtQuick 1.1
import com.nokia.symbian 1.1

ListItemFrame {
    id: root

    property alias iconSource: icon.source
    property alias title: titleText.text
    property alias subTitle: subTitleText.text

    signal clicked

    implicitWidth: screen.width
    implicitHeight: platformStyle.graphicSizeLarge

    Image {
        id: icon
        anchors {
            left: parent.left; top: parent.top; bottom: parent.bottom
            margins: platformStyle.paddingLarge
        }
        width: height
        sourceSize { width: width; height: height }
    }

    Column {
        anchors {
            left: iconSource == "" ? parent.left : icon.right
            leftMargin: iconSource == "" ? platformStyle.paddingLarge : platformStyle.paddingMedium
            verticalCenter: parent.verticalCenter
        }
        spacing: platformStyle.paddingSmall

        Text {
            id: titleText
            font.pixelSize: platformStyle.fontSizeLarge
            color: platformStyle.colorNormalLight
        }

        Text {
            id: subTitleText
            font.pixelSize: platformStyle.fontSizeSmall
            color: platformStyle.colorNormalMid
        }
    }

    MouseArea {
        anchors.fill: parent
        onPressed: root.opacity = 0.8
        onReleased: root.opacity = 1
        onCanceled: root.opacity = 1
        onClicked: root.clicked()
    }
}
