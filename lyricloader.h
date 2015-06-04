#ifndef LYRICLOADER_H
#define LYRICLOADER_H

#include <QObject>
#include <QPointer>
#include <QDeclarativeParserStatus>

namespace QJson { class Parser; }

class QNetworkAccessManager;
class QNetworkReply;

class LyricLoader : public QObject, public QDeclarativeParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QDeclarativeParserStatus)
    Q_PROPERTY(QStringList lyric READ lyric NOTIFY lyricChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(int lineIndex READ lineIndex NOTIFY lineIndexChanged)
public:
    explicit LyricLoader(QObject *parent = 0);
    ~LyricLoader();

    void classBegin();
    void componentComplete();

    Q_INVOKABLE bool loadFromFile(const QString& fileName);
    Q_INVOKABLE void loadFromMusicId(const QString& musicId);

    QStringList lyric() const;
    bool loading() const;
    int lineIndex() const;

signals:
    void lyricChanged();
    void loadingChanged();
    void lineIndexChanged();

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
    QStringList lrcLines;
    int currentIndex;

    bool isComponentComplete;
};

#endif // LYRICLOADER_H
