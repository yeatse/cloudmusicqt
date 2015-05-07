#include <QtGui/QApplication>
#include <QtDeclarative>
#include <QWebSettings>

#include "qmlapplicationviewer.h"
#include "networkaccessmanagerfactory.h"
#include "qmlapi.h"
#include "musicfetcher.h"
#include "musiccollector.h"
#include "blurreditem.h"
#include "musiccollector.h"

//#define PROXY_HOST "localhost"

#ifdef PROXY_HOST
#include <QNetworkProxy>
#endif

Q_DECL_EXPORT int main(int argc, char *argv[])
{
#ifdef Q_OS_SYMBIAN
    QApplication::setAttribute((Qt::ApplicationAttribute)11);   //Qt::AA_CaptureMultimediaKeys
#endif
    QScopedPointer<QApplication> app(createApplication(argc, argv));

    app->setApplicationName("CloudMusic");
    app->setOrganizationName("Yeatse");
    app->setApplicationVersion(VER);

#ifdef PROXY_HOST
    QNetworkProxy::setApplicationProxy(QNetworkProxy(QNetworkProxy::HttpProxy, PROXY_HOST, 8888));
#endif

    qmlRegisterType<MusicInfo>("com.yeatse.cloudmusic", 1, 0, "MusicInfo");
    qmlRegisterType<MusicFetcher>("com.yeatse.cloudmusic", 1, 0, "MusicFetcher");
    qmlRegisterType<BlurredItem>("com.yeatse.cloudmusic", 1, 0, "BlurredItem");

    QWebSettings::globalSettings()->setUserStyleSheetUrl(QUrl::fromLocalFile("qml/js/default_theme.css"));

    QScopedPointer<QmlApplicationViewer> viewer(new QmlApplicationViewer);
    viewer->setAttribute(Qt::WA_OpaquePaintEvent);
    viewer->setAttribute(Qt::WA_NoSystemBackground);
    viewer->viewport()->setAttribute(Qt::WA_OpaquePaintEvent);
    viewer->viewport()->setAttribute(Qt::WA_NoSystemBackground);
    viewer->setOrientation(QmlApplicationViewer::ScreenOrientationLockPortrait);

    QScopedPointer<NetworkAccessManagerFactory> factory(new NetworkAccessManagerFactory);
    viewer->engine()->setNetworkAccessManagerFactory(factory.data());

    viewer->rootContext()->setContextProperty("qmlApi", new QmlApi(viewer.data()));
    viewer->rootContext()->setContextProperty("collector", new MusicCollector(viewer.data()));

    viewer->setMainQmlFile(QLatin1String("qml/cloudmusicqt/main.qml"));
    viewer->showExpanded();

    return app->exec();
}
