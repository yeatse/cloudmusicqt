#include "qmlapi.h"

#include <QDateTime>
#include <QApplication>
#include <QPixmap>
#include <QDesktopServices>
#include <QDebug>

#ifdef Q_OS_SYMBIAN
#include <akndiscreetpopup.h>
#include <avkon.hrh>
#endif

#include "networkaccessmanagerfactory.h"
#include "userconfig.h"
#include "musicfetcher.h"

#include "qjson/json_parser.hh"

QmlApi::QmlApi(QObject *parent) : QObject(parent),
    mParser(new QJson::Parser)
{
}

QmlApi::~QmlApi()
{
    delete mParser;
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

QString QmlApi::getUserId()
{
    return UserConfig::Instance()->getSetting(UserConfig::KeyUserId).toString();
}

void QmlApi::saveUserId(const QString &id)
{
    UserConfig::Instance()->setSetting(UserConfig::KeyUserId, id);
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

void QmlApi::showNotification(const QString &title, const QString &text, const int &commandId)
{
#ifdef Q_OS_SYMBIAN
    TPtrC16 sTitle(static_cast<const TUint16 *>(title.utf16()), title.length());
    TPtrC16 sText(static_cast<const TUint16 *>(text.utf16()), text.length());
    TUid uid = TUid::Uid(0x2006DFF5);
    TRAP_IGNORE(CAknDiscreetPopup::ShowGlobalPopupL(
                    sTitle,
                    sText,
                    KAknsIIDNone,
                    KNullDesC,
                    0,
                    0,
                    KAknDiscreetPopupDurationLong,
                    commandId,
                    this,
                    uid ));
#else
    qDebug() << "showNotification:" << title << text << commandId;
#endif
}

static const int MaxAccurateNumberInQML = 65535;

static QVariant fixVariant(const QVariant& variant)
{
    QVariant result(variant);
    if (result.type() == QVariant::ULongLong) {
        quint64 value = result.toULongLong();
        if (value > MaxAccurateNumberInQML)
            result.convert(QVariant::String);
        else
            result.convert(QVariant::Int);
    }
    else if (result.type() == QVariant::Map) {
        QVariantMap map = result.toMap();
        for (QVariantMap::iterator i = map.begin(); i != map.end(); i++) {
            i.value() = fixVariant(i.value());
        }
        result = map;
    }
    else if (result.type() == QVariant::List) {
        QVariantList list = result.toList();
        for (QVariantList::iterator i = list.begin(); i != list.end(); i++) {
            *i = fixVariant(*i);
        }
        result = list;
    }
    return result;
}

QVariant QmlApi::jsonParse(const QString &text)
{
    return fixVariant(mParser->parse(text.toUtf8()));
}

bool QmlApi::compareVariant(const QVariant &left, const QVariant &right)
{
    return left == right;
}

QString QmlApi::getNetEaseImageUrl(const QString &imgId)
{
    return MusicInfo::getPictureUrl(imgId.toAscii());
}

#ifdef Q_OS_SYMBIAN
void QmlApi::ProcessCommandL(TInt aCommandId)
{
    emit processCommand(aCommandId);
}
#endif
