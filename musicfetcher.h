#ifndef MUSICFETCHER_H
#define MUSICFETCHER_H

#include <QObject>
#include <QPointer>
#include <QVariant>
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

    static MusicData* fromVariant(const QVariant& data, int ver = 0);
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

    static AlbumData* fromVariant(const QVariant& data, int ver = 0);
    ~AlbumData();
};

class MusicInfo : public QObject
{
    Q_OBJECT
    Q_ENUMS(Quality)
    Q_PROPERTY(QString musicId READ musicId CONSTANT)
    Q_PROPERTY(QString musicName READ musicName CONSTANT)
    Q_PROPERTY(int musicDuration READ musicDuration CONSTANT)
    Q_PROPERTY(bool starred READ isStarred CONSTANT)
    Q_PROPERTY(QString commentId READ commentId CONSTANT)
    Q_PROPERTY(QString albumName READ albumName CONSTANT)
    Q_PROPERTY(QString albumImageUrl READ albumImageUrl CONSTANT)
    Q_PROPERTY(QString artistsDisplayName READ artistsDisplayName CONSTANT)
public:
    enum Quality { LowQuality, MiddleQuality, HighQuality };

    explicit MusicInfo(QObject* parent = 0);
    ~MusicInfo();

    Q_INVOKABLE QString getUrl(Quality quality) const;

    QString musicId() const;
    QString musicName() const;
    int musicDuration() const;
    bool isStarred() const;
    QString commentId() const;

    QString albumName() const;
    QString albumImageUrl() const;
    QString artistsDisplayName() const;

    MusicData* getMusicData(Quality quality) const;
    int fileSize(Quality quality) const;
    QString extension(Quality quality) const;
    QVariant getRawData() const;

    static QString getMusicUrl(const QByteArray& id, const QString& ext = "mp3");
    static QString getPictureUrl(const QByteArray& id);
    static MusicInfo* fromVariant(const QVariant& data, int ver = 0, QObject* parent = 0);

private:
    QVariant rawData;
    int dataVersion;

    QString id;
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
    Q_INVOKABLE void loadPlayList(const int &listId);
    Q_INVOKABLE void loadDJDetail(const int &djId);
    Q_INVOKABLE void searchSongs(const QString& text);

    Q_INVOKABLE void loadFromFetcher(MusicFetcher* other = 0);
    Q_INVOKABLE void loadFromDownloader();
    Q_INVOKABLE void loadFromMusicInfo(MusicInfo* info = 0);

    Q_INVOKABLE MusicInfo* dataAt(const int& index) const;

    Q_INVOKABLE QVariantMap getRawData() const;

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
    QVariantMap mRawData;

    QList<MusicInfo*> mDataList;
    QPointer<QNetworkReply> mCurrentReply;

    QNetworkAccessManager* mNetworkAccessManager;
    QJson::Parser* mParser;

    bool isComponentComplete;
    int mLastError;
};

#endif // MUSICFETCHER_H
