#ifndef QMLAPI_H
#define QMLAPI_H

#include <QObject>

class QDeclarativeItem;
class QmlApi : public QObject
{
    Q_OBJECT
public:
    explicit QmlApi(QObject *parent = 0);

    Q_INVOKABLE QString getCookieToken();
    Q_INVOKABLE void takeScreenShot();
};

#endif // QMLAPI_H
