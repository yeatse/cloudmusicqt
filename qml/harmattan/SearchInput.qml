import QtQuick 1.1
import com.nokia.symbian 1.1

TextField {
    id: root

    property bool busy: false

    signal typeStopped
    signal cleared

    onTextChanged: {
        inputTimer.restart()
    }

    platformLeftMargin: searchIcon.width + platformStyle.paddingMedium
    platformRightMargin: clearButton.width + platformStyle.paddingMedium

    Timer {
        id: inputTimer
        interval: 500
        onTriggered: root.typeStopped()
    }

    Image {
        id: searchIcon
        anchors { left: parent.left; leftMargin: platformStyle.paddingMedium; verticalCenter: parent.verticalCenter }
        height: platformStyle.graphicSizeSmall
        width: platformStyle.graphicSizeSmall
        sourceSize { width: width; height: height }
        source: privateStyle.toolBarIconPath("toolbar-search", true)
        visible: !busy
    }

    BusyIndicator {
        anchors.fill: searchIcon
        visible: busy
        running: true
    }

    Item {
        id: clearButton
        anchors { right: parent.right; rightMargin: platformStyle.paddingMedium; verticalCenter: parent.verticalCenter }
        height: platformStyle.graphicSizeSmall
        width: platformStyle.graphicSizeSmall
        opacity: root.activeFocus ? 1 : 0
        Behavior on opacity {
            NumberAnimation { duration: 100 }
        }
        Image {
            anchors.fill: parent
            sourceSize { width: platformStyle.graphicSizeSmall; height: platformStyle.graphicSizeSmall }
            source: privateStyle.imagePath(clearMouseArea.pressed ? "qtg_graf_textfield_clear_pressed"
                                                                  : "qtg_graf_textfield_clear_normal",
                                                                    root.platformInverted)
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
