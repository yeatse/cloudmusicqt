#include <QtGui/QApplication>
#include "qmlapplicationviewer.h"

Q_DECL_EXPORT int main(int argc, char *argv[])
{
    QApplication::setAttribute((Qt::ApplicationAttribute)11);   //Qt::AA_CaptureMultimediaKeys

    QScopedPointer<QApplication> app(createApplication(argc, argv));

    QScopedPointer<QmlApplicationViewer> viewer(new QmlApplicationViewer);
    viewer->setMainQmlFile(QLatin1String("qml/cloudmusicqt/main.qml"));
    viewer->showExpanded();

    return app->exec();
}
