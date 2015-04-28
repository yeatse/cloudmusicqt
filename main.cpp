#include <QtGui/QApplication>
#include "qmlapplicationviewer.h"
#include <QMediaPlayer>
#include <QBuffer>
#include <QNetworkRequest>
#include <QNetworkProxy>

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QScopedPointer<QApplication> app(createApplication(argc, argv));

    QNetworkProxy::setApplicationProxy(QNetworkProxy(QNetworkProxy::HttpProxy, "192.168.1.64", 8888));

    QmlApplicationViewer viewer;
    viewer.setMainQmlFile(QLatin1String("qml/cloudmusicqt/main.qml"));
    viewer.showExpanded();

    QMediaPlayer* player = new QMediaPlayer;
    QNetworkRequest req(QUrl("http://yeatse.com/123.mp3"));
    player->setMedia(req);
    player->setVolume(10);
    player->play();

    return app->exec();
}
