#include <QtGui/QApplication>
#include <QtDeclarative>
#include <QWebSettings>

#include "qmlapplicationviewer.h"
#include "networkaccessmanagerfactory.h"
#include "qmlapi.h"
#include "musicfetcher.h"

//#ifdef Q_WS_SIMULATOR
#include <QNetworkProxy>
//#endif

Q_DECL_EXPORT int main(int argc, char *argv[])
{
#ifdef Q_OS_SYMBIAN
    QApplication::setAttribute((Qt::ApplicationAttribute)11);   //Qt::AA_CaptureMultimediaKeys
#endif
    QScopedPointer<QApplication> app(createApplication(argc, argv));

    app->setApplicationName("CloudMusic");
    app->setOrganizationName("Yeatse");
    app->setApplicationVersion(VER);

//#ifdef Q_WS_SIMULATOR
    QNetworkProxy::setApplicationProxy(QNetworkProxy(QNetworkProxy::HttpProxy, "192.168.1.64", 8888));
//#endif

    qmlRegisterUncreatableType<MusicData>("com.yeatse.cloudmusic", 1, 0, "MusicData", "");
    qmlRegisterType<MusicFetcher>("com.yeatse.cloudmusic", 1, 0, "MusicFetcher");

    QWebSettings::globalSettings()->setUserStyleSheetUrl(QUrl::fromLocalFile("qml/js/default_theme.css"));

    QScopedPointer<QmlApplicationViewer> viewer(new QmlApplicationViewer);
    viewer->setAttribute(Qt::WA_OpaquePaintEvent);
    viewer->setAttribute(Qt::WA_NoSystemBackground);
    viewer->viewport()->setAttribute(Qt::WA_OpaquePaintEvent);
    viewer->viewport()->setAttribute(Qt::WA_NoSystemBackground);

    QScopedPointer<NetworkAccessManagerFactory> factory(new NetworkAccessManagerFactory);
    viewer->engine()->setNetworkAccessManagerFactory(factory.data());

    viewer->rootContext()->setContextProperty("qmlApi", new QmlApi(viewer.data()));

    viewer->setMainQmlFile(QLatin1String("qml/cloudmusicqt/main.qml"));
    viewer->showExpanded();

    return app->exec();
}
