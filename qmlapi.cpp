#include "qmlapi.h"

#include "networkaccessmanagerfactory.h"

#include <QDateTime>
#include <QApplication>
#include <QPixmap>
#include <QDesktopServices>
#include <QWidget>

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

void QmlApi::takeScreenShot()
{
    QPixmap p = QPixmap::grabWidget(QApplication::activeWindow());
    QString fileName = QString("%1/%2_%3.png")
            .arg(QDesktopServices::storageLocation(QDesktopServices::PicturesLocation),
                 qApp->applicationName(),
                 QDateTime::currentDateTime().toString("yyyy_MM_dd_hh_mm_ss"));

    p.save(fileName);
}
