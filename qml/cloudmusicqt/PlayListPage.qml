import QtQuick 1.1
import com.nokia.symbian 1.1
import com.yeatse.cloudmusic 1.0

Page {
    id: page

    property int listId
    property bool requstLoad: true

    onStatusChanged: {
        if (status == PageStatus.Active && requstLoad) {
            requstLoad = false
            fetcher.loadPlayList(listId)
        }
    }

    tools: ToolBarLayout {
        ToolButton {
            iconSource: "toolbar-back"
            onClicked: pageStack.pop()
        }
    }

    MusicFetcher {
        id: fetcher
        onLoadingChanged: {
            if (!loading && !lastError) {
                listModel.clear()
                for (var i = 0; i < count; i++) {
                    var data = dataAt(i)
                    var prop = {
                        name: data.musicName,
                        desc: data.artistsDisplayName + " - " + data.albumName
                    }
                    listModel.append(prop)
                }
            }
        }
    }

    ListView {
        id: listView
        anchors.fill: parent
        model: ListModel { id: listModel }
        delegate: CategoryItem {
            title: name
            subTitle: desc
        }
    }
}
