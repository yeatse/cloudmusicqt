#include "networkaccessmanagerfactory.h"

#include <QNetworkAccessManager>
#include <QSettings>
#include <QDebug>

#include "userconfig.h"

QNetworkAccessManager* NetworkAccessManagerFactory::create(QObject *parent)
{
    QNetworkAccessManager* manager = new QNetworkAccessManager(parent);

    QNetworkCookieJar* cookieJar = NetworkCookieJar::Instance();
    manager->setCookieJar(cookieJar);
    cookieJar->setParent(0);

    return manager;
}

NetworkCookieJar::NetworkCookieJar() : QNetworkCookieJar()
{
    loadCookies();
}

NetworkCookieJar::~NetworkCookieJar()
{
    saveCookies();
}

void NetworkCookieJar::clearCookies()
{
    setAllCookies(QList<QNetworkCookie>());
}

void NetworkCookieJar::loadCookies()
{
    QByteArray data = QSettings().value(UserConfig::KeyCookies).toByteArray();
    setAllCookies(QNetworkCookie::parseCookies(data));
}

void NetworkCookieJar::saveCookies()
{
    QList<QNetworkCookie> list = allCookies();
    QByteArray data;
    foreach (const QNetworkCookie& cookie, list) {
        if (!cookie.isSessionCookie() && cookie.domain().endsWith("music.163.com")) {
            data.append(cookie.toRawForm());
            data.append("\n");
        }
    }
    QSettings().setValue(UserConfig::KeyCookies, data);
}
