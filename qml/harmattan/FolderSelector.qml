import QtQuick 1.1
import com.nokia.meego 1.0
import Qt.labs.folderlistmodel 1.0
import "./UIConstants.js" as UI

Sheet {
    id: root

    property string folder

    property bool _isClosing: false
    onStatusChanged: {
        if (status == DialogStatus.Closing) {
            _isClosing = true
        }
        else if (status == DialogStatus.Closed && _isClosing) {
            root.destroy(500)
        }
    }
    Component.onCompleted: open()

    acceptButtonText: "选择"
    rejectButtonText: "取消"

    content: [
        ListHeading {
            id: heading
            Label {
                anchors.fill: parent.paddingItem
                horizontalAlignment: Text.AlignRight
                verticalAlignment: Text.AlignVCenter
                text: root.folder
                elide: Text.ElideLeft
            }
        },
        ListView {
            id: listView
            anchors {
                fill: parent; topMargin: heading.height
            }
            clip: true
            model: FolderListModel {
                id: folderListModel
                folder: "file://" + root.folder
                nameFilters: [""]
                showDirs: true
                showDotAndDotDot: false
                showOnlyReadable: true
            }
            header: ListItemFrame {
                Label {
                    anchors {
                        fill: parent; margins: UI.PADDING_LARGE
                    }
                    platformStyle: LabelStyle {
                        fontPixelSize: UI.FONT_LARGE
                    }
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: ".."
                }
                height: visible ? implicitHeight : 0
                visible: root.folder != qmlApi.getHomePath()
                onClicked: root.folder = qmlApi.cleanPath(root.folder + "/..")
            }
            delegate: ListItemFrame {
                Label {
                    anchors {
                        fill: parent; margins: UI.PADDING_LARGE
                    }
                    platformStyle: LabelStyle {
                        fontPixelSize: UI.FONT_LARGE
                    }
                    verticalAlignment: Text.AlignVCenter
                    elide: Text.ElideRight
                    text: fileName
                }
                onClicked: root.folder = qmlApi.cleanPath(root.folder + "/" + fileName)
            }
        },
        ScrollDecorator {
            flickableItem: listView
        }
    ]
}
