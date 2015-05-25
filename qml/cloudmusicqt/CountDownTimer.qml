import QtQuick 1.1

QtObject {
    id: root

    signal triggered

    property bool active: false
    property int timeLeft: 30   // minutes

    property Timer timer: Timer {
        interval: 60 * 1000
        repeat: true
        running: root.active
        onTriggered: {
            if (--timeLeft <= 0) {
                root.triggered()
                root.active = false
            }
        }
    }
}
