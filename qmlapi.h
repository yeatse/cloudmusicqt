#ifndef QMLAPI_H
#define QMLAPI_H

#include <QObject>
#include <QVariant>

#ifdef Q_OS_SYMBIAN
#include <eikcmobs.h>
#endif

namespace QJson { class Parser; }

#ifdef Q_OS_SYMBIAN
class QmlApi : public QObject, public MEikCommandObserver
#else
class QmlApi : public QObject
#endif
{
    Q_OBJECT
public:
    explicit QmlApi(QObject *parent = 0);
    ~QmlApi();

    Q_INVOKABLE QString getCookieToken();

    Q_INVOKABLE QString getUserId();
    Q_INVOKABLE void saveUserId(const QString& id);

    Q_INVOKABLE void takeScreenShot();

    Q_INVOKABLE void showNotification(const QString& title, const QString& text,
                                      const int& commandId = 0);

    Q_INVOKABLE QVariant jsonParse(const QString& text);

    Q_INVOKABLE bool compareVariant(const QVariant& left, const QVariant& right);

    Q_INVOKABLE QString getNetEaseImageUrl(const QString& imgId);

    Q_INVOKABLE bool isFileExists(const QString& fileName);

#ifdef Q_OS_SYMBIAN
    void ProcessCommandL(TInt aCommandId);
#endif

signals:
    void processCommand(int commandId);

private:
    QJson::Parser* mParser;
};

#endif // QMLAPI_H
