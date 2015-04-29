#ifndef USERCONFIG_H
#define USERCONFIG_H

#include <QObject>

#include "singletonbase.h"

class UserConfig : public QObject
{
    Q_OBJECT
    DECLARE_SINGLETON(UserConfig)
public:
    static const char* KeyCookies;

    ~UserConfig();

private:
    UserConfig();
};

#endif // USERCONFIG_H
