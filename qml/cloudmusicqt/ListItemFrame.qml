import QtQuick 1.1
import com.nokia.symbian 1.1

Item {
    id: root

    signal clicked

    implicitWidth: screen.width
    implicitHeight: platformStyle.graphicSizeLarge

    MouseArea {
        anchors.fill: parent
        onPressed: root.opacity = 0.8
        onReleased: root.opacity = 1
        onCanceled: root.opacity = 1
        onClicked: root.clicked()
    }
}
