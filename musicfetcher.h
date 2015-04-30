#ifndef MUSICFETCHER_H
#define MUSICFETCHER_H

#include <QObject>
#include <QList>
#include <QPointer>
#include <QDeclarativeParserStatus>

class QNetworkAccessManager;
class QNetworkReply;

namespace QJson { class Parser; }

class MusicFetcher;

class MusicData
{
public:
    int id;
    int size;
    QString extension;
    QByteArray dfsId;
    int bitrate;

    static MusicData* fromVariant(const QVariant& data);
    QString getUrl() const;
};

class ArtistData
{
public:
    int id;
    QString name;
    QString avatar;

    static ArtistData* fromVariant(const QVariant& data);
};

class AlbumData
{
public:
    int id;
    QString name;
    QString picUrl;
    QList<ArtistData*> artists;

    static AlbumData* fromVariant(const QVariant& data);
    ~AlbumData();
};

class MusicInfo : public QObject
{
    Q_OBJECT
    Q_ENUMS(Quality)
public:
    enum Quality { LowQuality, MiddleQuality, HighQuality };

    explicit MusicInfo(QObject* parent = 0);
    ~MusicInfo();

    Q_INVOKABLE QString getUrl(Quality quality) const;
    Q_INVOKABLE int fileSize(Quality quality) const;

private:
    int id;
    int duration;
    bool starred;
    QString name;
    QString commentThreadId;

    MusicData* lMusic;
    MusicData* mMusic;
    MusicData* hMusic;

    AlbumData* album;
    QList<ArtistData*> artists;

    friend class MusicFetcher;
};

class MusicFetcher : public QObject, public QDeclarativeParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QDeclarativeParserStatus)
    Q_PROPERTY(int count READ count NOTIFY dataChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
    Q_PROPERTY(int lastError READ lastError)
public:
    explicit MusicFetcher(QObject* parent = 0);
    ~MusicFetcher();

    void classBegin();
    void componentComplete();

    Q_INVOKABLE void loadPrivateFM();
    Q_INVOKABLE void loadRecommend(int offset = 0, bool total = true, int limit = 20);
    Q_INVOKABLE MusicInfo* dataAt(const int& index) const;
    Q_INVOKABLE void reset();

    int count() const;
    bool loading() const;
    int lastError() const;

signals:
    void dataChanged();
    void loadingChanged();

private slots:
    void requestFinished();

private:
    MusicInfo* createDataFromMap(const QVariant& data);

private:
    QList<MusicInfo*> mDataList;
    QPointer<QNetworkReply> mCurrentReply;

    QNetworkAccessManager* mNetworkAccessManager;
    QJson::Parser* mParser;

    bool isComponentComplete;
    int mLastError;
};

#endif // MUSICFETCHER_H
