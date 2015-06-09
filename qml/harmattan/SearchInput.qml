import QtQuick 1.1
import com.nokia.meego 1.0

import "./UIConstants.js" as UI

TextField {
    id: root

    property bool busy: false

    signal typeStopped
    signal cleared

    onTextChanged: {
        inputTimer.restart()
    }

    platformStyle: TextFieldStyle {
        paddingLeft: searchIcon.width + UI.PADDING_XLARGE
        paddingRight: clearButton.width + UI.PADDING_XLARGE
    }

    Timer {
        id: inputTimer
        interval: 500
        onTriggered: root.typeStopped()
    }

    Image {
        id: searchIcon
        anchors { left: parent.left; leftMargin: UI.PADDING_MEDIUM; verticalCenter: parent.verticalCenter }
        height: UI.SIZE_ICON_DEFAULT
        width: UI.SIZE_ICON_DEFAULT
        sourceSize { width: width; height: height }
        source: "image://theme/icon-m-common-search"
        visible: !busy
    }

    BusyIndicator {
        anchors.fill: searchIcon
        visible: busy
        running: true
    }

    Item {
        id: clearButton
        anchors { right: parent.right; rightMargin: UI.PADDING_MEDIUM; verticalCenter: parent.verticalCenter }
        height: UI.SIZE_ICON_DEFAULT
        width: UI.SIZE_ICON_DEFAULT
        opacity: root.activeFocus ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 100 }
        }
        Image {
            anchors.fill: parent
            sourceSize { width: UI.SIZE_ICON_DEFAULT; height: UI.SIZE_ICON_DEFAULT }
            source: "image://theme/icon-m-input-clear"
        }
        MouseArea {
            id: clearMouseArea
            anchors.fill: parent
            onClicked: {
                root.text = ""
                root.parent.forceActiveFocus()
                root.cleared()
            }
        }
    }
}
