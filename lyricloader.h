#ifndef LYRICLOADER_H
#define LYRICLOADER_H

#include <QObject>
#include <QPointer>
#include <QDeclarativeParserStatus>
#include <QStringList>

namespace QJson { class Parser; }

class QNetworkAccessManager;
class QNetworkReply;

class LyricLine;

class LyricLoader : public QObject, public QDeclarativeParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QDeclarativeParserStatus)
    Q_PROPERTY(QStringList lyric READ lyric NOTIFY lyricChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
public:
    explicit LyricLoader(QObject *parent = 0);
    ~LyricLoader();

    void classBegin();
    void componentComplete();

    Q_INVOKABLE bool loadFromFile(const QString& fileName);
    Q_INVOKABLE void loadFromMusicId(const QString& musicId);
    Q_INVOKABLE void saveToFile(const QString& fileName);
    Q_INVOKABLE int getLineByPosition(const int& millisec) const;

    QStringList lyric() const;
    bool loading() const;

signals:
    void lyricChanged();
    void loadingChanged();

private:
    void reset();
    bool processContent(const QString& content);

private slots:
    void requestFinished();

private:
    QJson::Parser* parser;
    QNetworkAccessManager* manager;
    QPointer<QNetworkReply> reply;

    QString rawData;
    QList<LyricLine*> lrcLines;

    bool isComponentComplete;
};

#endif // LYRICLOADER_H
