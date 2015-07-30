import QtQuick 1.1

Item {
    id: root

    property string buttonName: ""

    signal clicked

    width: 75
    height: 75

    Image {
        anchors.centerIn: parent
        source: "gfx/rdi_btn_" + buttonName + ".png"
    }

    MouseArea {
        anchors.fill: parent
        onClicked: root.clicked()
    }
}
