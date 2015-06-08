import QtQuick 1.1

Rectangle {
    id: root

    property int volume    // 0 ~ 100

    opacity: 0

    anchors.centerIn: parent

    implicitWidth: 150
    implicitHeight: 150

    color: "#F0000000"

    radius: 5

    function flash() {
        flashEffect.restart()
    }

    function volumeUp() {
        volume = Math.min(volume + 5, 100)
        flash()
    }

    function volumeDown() {
        volume = Math.max(volume - 5, 0)
        flash()
    }

    SequentialAnimation {
        id: flashEffect
        PropertyAnimation {
            target: root
            property: "opacity"
            easing.type: Easing.OutQuint
            to: 1
            duration: 500
        }
        PropertyAnimation {
            target: root
            property: "opacity"
            easing.type: Easing.InQuint
            to: 0
            duration: 500
        }
    }

    Row {
        anchors.centerIn: parent
        Image {
            id: icon
            anchors.verticalCenter: parent.verticalCenter
            source: "gfx/volume.svg"
        }
        Text {
            anchors.verticalCenter: parent.verticalCenter
            text: root.volume
            font.pixelSize: icon.height - 10
            color: "white"
        }
    }
}
