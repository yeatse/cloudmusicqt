import QtQuick 1.1
import com.nokia.symbian 1.1
import com.yeatse.cloudmusic 1.0

Item {
    id: root

    LyricLoader {
        id: loader
    }

    ListView {
        id: view
        anchors.fill: parent
        model: loader.lyric
        delegate: Text {
        }
    }
}
