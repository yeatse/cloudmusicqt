#ifndef USERCONFIG_H
#define USERCONFIG_H

#include <QObject>
#include <QVariant>

#include "singletonbase.h"

class QSettings;
class UserConfig : public QObject
{
    Q_OBJECT
    DECLARE_SINGLETON(UserConfig)
public:
    static const char* KeyCookies;
    static const char* KeyUserId;
    static const char* KeyDownloadQuality;
    static const char* KeyDownloadDirectory;
    static const char* KeyShowAccessPointTip;

    ~UserConfig();

    QVariant getSetting(const QString& key, const QVariant& defaultValue = QVariant()) const;
    void setSetting(const QString& key, const QVariant& value);

private:
    UserConfig();
    QSettings* settings;
};

#endif // USERCONFIG_H
