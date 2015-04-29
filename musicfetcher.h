#ifndef MUSICFETCHER_H
#define MUSICFETCHER_H

#include <QObject>
#include <QList>
#include <QPointer>

class QDeclarativeView;
class QNetworkAccessManager;
class QNetworkReply;

namespace QJson { class Parser; }

class MusicFetcher;

class MusicData : public QObject
{
    Q_OBJECT
public:
    enum Quality {

    }
    explicit MusicData(QObject* parent = 0);

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

class MusicFetcher : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int count READ count NOTIFY dataChanged)
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
public:
    explicit MusicFetcher(QDeclarativeView *parent = 0);
    ~MusicFetcher();

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
};

#endif // MUSICFETCHER_H
