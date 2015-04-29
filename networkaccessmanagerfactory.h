#ifndef NETWORKACCESSMANAGERFACTORY_H
#define NETWORKACCESSMANAGERFACTORY_H

#include <QDeclarativeNetworkAccessManagerFactory>
#include <QNetworkCookieJar>

#include "singletonbase.h"

class NetworkAccessManagerFactory : public QDeclarativeNetworkAccessManagerFactory
{
public:
    QNetworkAccessManager* create(QObject *parent);
};

class NetworkCookieJar : public QNetworkCookieJar
{
    Q_OBJECT
    DECLARE_SINGLETON(NetworkCookieJar)
public:
    ~NetworkCookieJar();
    void clearCookies();

private:
    NetworkCookieJar();
    void loadCookies();
    void saveCookies();
};

#endif // NETWORKACCESSMANAGERFACTORY_H
