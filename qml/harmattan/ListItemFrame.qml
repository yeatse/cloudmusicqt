import QtQuick 1.1
import "UIConstants.js" as UI

Item {
    id: root

    signal clicked
    signal pressAndHold

    implicitWidth: ListView.view ? ListView.view.width : parent.width
    implicitHeight: UI.LIST_ITEM_HEIGHT_DEFAULT

    MouseArea {
        anchors.fill: parent
        onPressed: root.opacity = 0.8
        onReleased: root.opacity = 1
        onCanceled: root.opacity = 1
        onClicked: root.clicked()
        onPressAndHold: root.pressAndHold()
    }
}
