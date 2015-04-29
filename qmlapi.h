#ifndef QMLAPI_H
#define QMLAPI_H

#include <QObject>

class QmlApi : public QObject
{
    Q_OBJECT
public:
    explicit QmlApi(QObject *parent = 0);

    Q_INVOKABLE QString getCookieToken();
};

#endif // QMLAPI_H
