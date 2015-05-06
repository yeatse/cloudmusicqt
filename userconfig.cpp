#include "userconfig.h"

#include <QSettings>

const char* UserConfig::KeyCookies = "cookies";
const char* UserConfig::KeyUserId = "userId";

UserConfig::UserConfig() : QObject(), settings(0)
{
    settings = new QSettings(this);
}

UserConfig::~UserConfig()
{
}

QVariant UserConfig::getSetting(const QString &key, const QVariant &defaultValue) const
{
    return settings->value(key, defaultValue);
}

void UserConfig::setSetting(const QString &key, const QVariant &value)
{
    settings->setValue(key, value);
}
