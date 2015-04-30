#ifndef MUSICFETCHER_H
#define MUSICFETCHER_H

#include <QObject>
#include <QList>
#include <QVariant>
#include <QPointer>
#include <QDeclarativeParserStatus>

class QNetworkAccessManager;
class QNetworkReply;

namespace QJson { class Parser; }

class MusicFetcher;

class MusicData : public QObject
{
    Q_OBJECT
public:
    enum Quality { LowQuality, MiddleQuality, HighQuality };

    explicit MusicData(QObject* parent = 0);

    Q_INVOKABLE QString getUrl(Quality quality) const;
    Q_INVOKABLE int fileSize(Quality quality) const;

private:
    bool mStarred;
    QString mMp3Url;
    QString mName;
    int mId;
    int mDuration;
    QVariant mAlbum;
    QVariant mArtists;


    friend class MusicFetcher;
};

class MusicFetcher : public QObject, public QDeclarativeParserStatus
{
    Q_OBJECT
    Q_INTERFACES(QDeclarativeParserStatus)
    Q_PROPERTY(int count READ count NOTIFY dataChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
public:
    explicit MusicFetcher(QObject* parent = 0);
    ~MusicFetcher();

    void classBegin();
    void componentComplete();

    Q_INVOKABLE void loadRecommend(int offset = 0, bool total = true, int limit = 20);
    Q_INVOKABLE MusicData* dataAt(const int& index) const;

    int count() const;
    bool loading() const;

signals:
    void dataChanged();
    void loadingChanged();

private slots:
    void requestFinished();

private:
    MusicData* createDataFromMap(const QVariant& data);

private:
    QList<MusicData*> mDataList;
    QPointer<QNetworkReply> mCurrentReply;

    QNetworkAccessManager* mNetworkAccessManager;
    QJson::Parser* mParser;

    bool isComponentComplete;
};

#endif // MUSICFETCHER_H
