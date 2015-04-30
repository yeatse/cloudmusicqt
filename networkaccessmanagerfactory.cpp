#include "networkaccessmanagerfactory.h"

#include <QNetworkAccessManager>
#include <QSettings>
#include <QSystemDeviceInfo>
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
    loadExtraCookies();
}

void NetworkCookieJar::loadCookies()
{
    QByteArray storedCookies = QSettings().value(UserConfig::KeyCookies).toByteArray();
    setAllCookies(QNetworkCookie::parseCookies(storedCookies));

    loadExtraCookies();
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

void NetworkCookieJar::loadExtraCookies()
{
    QList<QNetworkCookie> extraCookies;
    extraCookies.append(QNetworkCookie("appver", "1.6.1.82809"));
    extraCookies.append(QNetworkCookie("channel", "netease"));
    extraCookies.append(QNetworkCookie("deviceId", QtMobility::QSystemDeviceInfo().uniqueDeviceID().toUpper()));
    extraCookies.append(QNetworkCookie("os", "pc"));
    extraCookies.append(QNetworkCookie("osver", "Microsoft-Windows-8-Professional-build-9200-64bit"));
    setCookiesFromUrl(extraCookies, QUrl("http://music.163.com"));
}
