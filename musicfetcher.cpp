#include "musicfetcher.h"

#include <QtDeclarative>
#include <QDeclarativeView>
#include <QDeclarativeEngine>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QCryptographicHash>
#include <QDateTime>

#include "qjson/parser.h"

static const char* ApiBaseUrl = "http://music.163.com/api";

static const char* RequestOptionQuery = "query";
static const char* RequestOptionReload = "reload";

static const char* OptionQueryPlayList = "playlist";
static const char* OptionQueryDJDetail = "djDetail";

MusicData* MusicData::fromVariant(const QVariant &data, int ver)
{
    if (data.isNull() || !data.canConvert(QVariant::Map))
        return 0;

    MusicData* result = new MusicData;
    const QVariantMap& map = data.toMap();

    if (ver == 0) {
        result->id = map.value("id").toInt();
        result->size = map.value("size").toInt();
        result->extension = map.value("extension").toString();
        result->dfsId = map.value("dfsId").toByteArray();
        result->bitrate = map.value("bitrate").toInt();
    }
    else {
        result->id = 0;
        result->size = map.value("size").toInt();
        result->extension = "mp3";
        result->dfsId = map.value("fid").toByteArray();
        result->bitrate = map.value("br").toInt();
    }

    return result;
}

ArtistData* ArtistData::fromVariant(const QVariant &data)
{
    if (data.isNull() || !data.canConvert(QVariant::Map))
        return 0;

    ArtistData* result = new ArtistData;
    const QVariantMap& map = data.toMap();

    result->id = map.value("id").toInt();
    result->name = map.value("name").toString();
    result->avatar = map.value("img1v1Url").toString();

    return result;
}

AlbumData::~AlbumData()
{
    qDeleteAll(artists);
}

AlbumData* AlbumData::fromVariant(const QVariant &data, int ver)
{
    if (data.isNull() || !data.canConvert(QVariant::Map))
        return 0;

    AlbumData* result = new AlbumData;
    const QVariantMap& map = data.toMap();

    if (ver == 0) {
        result->id = map.value("id").toInt();
        result->name = map.value("name").toString();
        result->picUrl = map.value("picUrl").toString();

        foreach (const QVariant& artistData, map.value("artists").toList()) {
            ArtistData* artist = ArtistData::fromVariant(artistData);
            if (artist) result->artists.append(artist);
        }
    }
    else {
        result->id = map.value("id").toInt();
        result->name = map.value("name").toString();
        result->picUrl = MusicInfo::getPictureUrl(map.value("picStr").toByteArray());
    }

    return result;
}

MusicInfo::MusicInfo(QObject *parent) : QObject(parent),
    dataVersion(0), lMusic(0), mMusic(0), hMusic(0), album(0)
{
}

MusicInfo::~MusicInfo()
{
    delete lMusic;
    delete mMusic;
    delete hMusic;
    delete album;
    qDeleteAll(artists);
}

QString MusicInfo::getUrl(Quality quality) const
{
    MusicData* data = getMusicData(quality);
    return data ? getMusicUrl(data->dfsId, data->extension) : "";
}

QString MusicInfo::musicId() const
{
    return id;
}

QString MusicInfo::musicName() const
{
    return name;
}

int MusicInfo::musicDuration() const
{
    return duration;
}

bool MusicInfo::isStarred() const
{
    return starred;
}

QString MusicInfo::albumName() const
{
    return album ? album->name : "";
}

QString MusicInfo::albumImageUrl() const
{
    return album ? album->picUrl : "";
}

QString MusicInfo::artistsDisplayName() const
{
    QStringList list;
    foreach (ArtistData* artist, artists) {
        list.append(artist->name);
    }
    return list.join(",");
}

MusicData* MusicInfo::getMusicData(Quality quality) const
{
    if (quality == LowQuality) return lMusic;
    if (quality == MiddleQuality) return mMusic;
    if (quality == HighQuality) return hMusic;
    return 0;
}

int MusicInfo::fileSize(Quality quality) const
{
    MusicData* data = getMusicData(quality);
    return data ? data->size : 0;
}

QString MusicInfo::extension(Quality quality) const
{
    MusicData* data = getMusicData(quality);
    return data ? data->extension : "";
}

QVariant MusicInfo::getRawData() const
{
    return rawData;
}

static QByteArray getEncryptedId(const QByteArray& songId)
{
    QByteArray result;
    QByteArray magic = "3go8&$8*3*3h0k(2)2";
    for (int i = 0; i < songId.length(); i++)
        result[i] = songId.at(i) ^ magic.at(i % magic.length());
    result = QCryptographicHash::hash(result, QCryptographicHash::Md5).toBase64();
    result.replace('/', '_');
    result.replace('+', "-");
    return result;
}

QString MusicInfo::getMusicUrl(const QByteArray &id, const QString &ext)
{
    static int control = 0;
    return QString("http://m%1.music.126.net/%2/%3.%4?v=%5")
            .arg(/*QString::number(control++ % 2 + 1)*/"2", getEncryptedId(id), id, ext,
                 QString::number(QDateTime::currentDateTime().toTime_t() % 1000000000));
}

QString MusicInfo::getPictureUrl(const QByteArray &id)
{
    static int control = 0;
    return QString("http://p%1.music.126.net/%2/%3.jpg")
            .arg(QString::number(control++ % 2 + 3), getEncryptedId(id), id);
}

MusicInfo* MusicInfo::fromVariant(const QVariant &data, int ver, QObject *parent)
{
    if (data.isNull() || !data.canConvert(QVariant::Map))
        return 0;

    MusicInfo* result = new MusicInfo(parent);
    const QVariantMap& map = data.toMap();

    result->rawData = data;
    result->dataVersion = ver;

    if (ver == 0) {
        result->starred = map.value("starred").toBool();
        result->name = map.value("name").toString();
        result->id = map.value("id").toString();
        result->duration = map.value("duration").toInt();
        result->commentThreadId = map.value("commentThreadId").toString();

        result->lMusic = MusicData::fromVariant(map.value("lMusic"));
        result->mMusic = MusicData::fromVariant(map.value("mMusic"));
        result->hMusic = MusicData::fromVariant(map.value("hMusic"));

        result->album = AlbumData::fromVariant(map.value("album"));

        foreach (const QVariant& artistData, map.value("artists").toList()) {
            ArtistData* artist = ArtistData::fromVariant(artistData);
            if (artist) result->artists.append(artist);
        }
    }
    else {
        result->starred = false;
        result->name = map.value("name").toString();
        result->id = map.value("id").toString();
        result->duration = map.value("dt").toInt();
        result->commentThreadId = QString("R_SO_4_%1").arg(result->id);

        result->lMusic = MusicData::fromVariant(map.value("l"), ver);
        result->mMusic = MusicData::fromVariant(map.value("m"), ver);
        result->hMusic = MusicData::fromVariant(map.value("h"), ver);

        result->album = AlbumData::fromVariant(map.value("al"), ver);

        foreach (const QVariant& ar, map.value("ar").toList()) {
            ArtistData* artist = ArtistData::fromVariant(ar);
            if (artist) result->artists.append(artist);
        }
    }

    return result;
}

MusicFetcher::MusicFetcher(QObject *parent) : QObject(parent),
    mNetworkAccessManager(0), mParser(new QJson::Parser),
    isComponentComplete(false), mLastError(0)
{
}

MusicFetcher::~MusicFetcher()
{
    delete mParser;
}

void MusicFetcher::classBegin()
{
    mNetworkAccessManager = qmlEngine(this)->networkAccessManager();
}

void MusicFetcher::componentComplete()
{
    isComponentComplete = true;
}

void MusicFetcher::loadPrivateFM()
{
    if (!isComponentComplete) return;

    if (mCurrentReply && mCurrentReply->isRunning())
        mCurrentReply->abort();

    QUrl url(QString(ApiBaseUrl).append("/radio/get"));
    mCurrentReply = mNetworkAccessManager->get(QNetworkRequest(url));
    mCurrentReply->setProperty(RequestOptionQuery, "data");
    connect(mCurrentReply, SIGNAL(finished()), SLOT(requestFinished()), Qt::QueuedConnection);

    mRawData.clear();
    mLastError = 0;
    emit loadingChanged();
}

void MusicFetcher::loadRecommend(int offset, bool total, int limit)
{
    if (!isComponentComplete) return;

    if (mCurrentReply && mCurrentReply->isRunning())
        mCurrentReply->abort();

    QUrl url(QString(ApiBaseUrl).append("/discovery/recommend/songs"));
    url.addEncodedQueryItem("offset", QByteArray::number(offset));
    url.addEncodedQueryItem("total", total ? "true" : "false");
    url.addEncodedQueryItem("limit", QByteArray::number(limit));

    mCurrentReply = mNetworkAccessManager->get(QNetworkRequest(url));
    mCurrentReply->setProperty(RequestOptionQuery, "recommend");
    mCurrentReply->setProperty(RequestOptionReload, true);
    connect(mCurrentReply, SIGNAL(finished()), SLOT(requestFinished()), Qt::QueuedConnection);

    mRawData.clear();
    mLastError = 0;
    emit loadingChanged();
}

void MusicFetcher::loadPlayList(const int &listId)
{
    if (!isComponentComplete) return;

    if (mCurrentReply && mCurrentReply->isRunning())
        mCurrentReply->abort();

    QUrl url(QString(ApiBaseUrl).append("/playlist/detail"));
    url.addEncodedQueryItem("id", QByteArray::number(listId));

    mCurrentReply = mNetworkAccessManager->get(QNetworkRequest(url));
    mCurrentReply->setProperty(RequestOptionQuery, OptionQueryPlayList);
    mCurrentReply->setProperty(RequestOptionReload, true);
    connect(mCurrentReply, SIGNAL(finished()), SLOT(requestFinished()), Qt::QueuedConnection);

    mRawData.clear();
    mLastError = 0;
    emit loadingChanged();
}

void MusicFetcher::loadDJDetail(const int &djId)
{
    if (!isComponentComplete) return;

    if (mCurrentReply && mCurrentReply->isRunning())
        mCurrentReply->abort();

    QUrl url(QString(ApiBaseUrl).append("/dj/program/detail"));
    url.addEncodedQueryItem("id", QByteArray::number(djId));

    mCurrentReply = mNetworkAccessManager->get(QNetworkRequest(url));
    mCurrentReply->setProperty(RequestOptionQuery, OptionQueryDJDetail);
    mCurrentReply->setProperty(RequestOptionReload, true);
    connect(mCurrentReply, SIGNAL(finished()), SLOT(requestFinished()), Qt::QueuedConnection);

    mRawData.clear();
    mLastError = 0;
    emit loadingChanged();
}

void MusicFetcher::loadFromFetcher(MusicFetcher *other)
{
    if (!other || this == other) return;

    reset();

    bool changed = false;
    mRawData = other->mRawData;
    foreach (MusicInfo* info, other->mDataList) {
        MusicInfo* copy = MusicInfo::fromVariant(info->rawData, info->dataVersion, this);
        if (copy) {
            changed = true;
            mDataList.append(copy);
        }
    }
    if (changed)
        emit dataChanged();
}

MusicInfo* MusicFetcher::dataAt(const int &index) const
{
    if (index >= 0 && index < mDataList.size())
        return mDataList.at(index);
    else
        return 0;
}

QVariantMap MusicFetcher::getRawData() const
{
    return mRawData;
}

void MusicFetcher::reset()
{
    if (!isComponentComplete) return;

    if (mCurrentReply && mCurrentReply->isRunning()) {
        mCurrentReply->abort();
        mCurrentReply = 0;
        emit loadingChanged();
    }

    mCurrentReply = 0;
    mLastError = 0;
    mRawData.clear();

    if (!mDataList.isEmpty()) {
        qDeleteAll(mDataList);
        mDataList.clear();
        emit dataChanged();
    }
}

int MusicFetcher::count() const
{
    return mDataList.size();
}

bool MusicFetcher::loading() const
{
    return mCurrentReply && mCurrentReply->isRunning();
}

int MusicFetcher::lastError() const
{
    return mLastError;
}

void MusicFetcher::requestFinished()
{
    sender()->deleteLater();
    if (mCurrentReply != sender())
        return;

    if (mCurrentReply->error() != QNetworkReply::NoError) {
        mLastError = mCurrentReply->error();
        emit loadingChanged();
        return;
    }

    if (mCurrentReply->property(RequestOptionReload).toBool() && !mDataList.isEmpty()) {
        qDeleteAll(mDataList);
        mDataList.clear();
        emit dataChanged();
    }

    mRawData = mParser->parse(mCurrentReply->readAll()).toMap();
    mLastError = mRawData.value("code", -1).toInt();
    if (mLastError != 200) {
        emit loadingChanged();
        return;
    }
    mLastError = 0;

    bool changed = false;
    QVariantList list;
    int dataVer = 0;

    QString query = mCurrentReply->property(RequestOptionQuery).toString();
    if (query == OptionQueryPlayList) {
        list = mRawData.value("result").toMap().value("tracks").toList();
    }
    else if (query == OptionQueryDJDetail) {
        list << mRawData.value("program").toMap().value("mainSong");
    }
    else {
        list = mRawData.value(query).toList();
    }

    foreach (const QVariant& item, list) {
        MusicInfo* data = MusicInfo::fromVariant(item, dataVer, this);
        if (data) {
            changed = true;
            mDataList.append(data);
        }
    }

    if (changed)
        emit dataChanged();

    emit loadingChanged();
}
