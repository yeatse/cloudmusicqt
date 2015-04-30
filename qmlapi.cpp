#include "qmlapi.h"

#include "networkaccessmanagerfactory.h"

#include <QDateTime>

QmlApi::QmlApi(QObject *parent) : QObject(parent)
{
}

QString QmlApi::getCookieToken()
{
    QList<QNetworkCookie> cookies = NetworkCookieJar::Instance()->cookiesForUrl(QUrl("http://music.163.com"));
    foreach (const QNetworkCookie& cookie, cookies) {
        if (cookie.name() == "MUSIC_U" && cookie.expirationDate() > QDateTime::currentDateTime()) {
            return cookie.value();
        }
    }
    return QString();
}
