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

MusicData* MusicData::fromVariant(const QVariant &data)
{
    if (data.isNull() || !data.canConvert(QVariant::Map))
        return 0;

    MusicData* result = new MusicData;
    const QVariantMap& map = data.toMap();

    result->id = map.value("id").toInt();
    result->size = map.value("size").toInt();
    result->extension = map.value("extension").toString();
    result->dfsId = map.value("dfsId").toByteArray();
    result->bitrate = map.value("bitrate").toInt();

    return result;
}

QString MusicData::getUrl() const
{
    static int __srand = 0;
    if (!__srand) {
        qsrand(QDateTime::currentDateTime().toTime_t());
        __srand = 1;
    }
    return QString("http://m%1.music.126.net/%2/%3.%4")
            .arg(QString::number(/*qrand() % 3 + 1*/2), getEncryptedId(dfsId), dfsId, extension);
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

AlbumData* AlbumData::fromVariant(const QVariant &data)
{
    if (data.isNull() || !data.canConvert(QVariant::Map))
        return 0;

    AlbumData* result = new AlbumData;
    const QVariantMap& map = data.toMap();

    result->id = map.value("id").toInt();
    result->name = map.value("name").toString();
    result->picUrl = map.value("picUrl").toString();

    foreach (const QVariant& artistData, map.value("artists").toList()) {
        ArtistData* artist = ArtistData::fromVariant(artistData);
        if (artist) result->artists.append(artist);
    }

    return result;
}

MusicInfo::MusicInfo(QObject *parent) : QObject(parent),
    lMusic(0), mMusic(0), hMusic(0), album(0)
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
    MusicData* data;

    if (quality == LowQuality) data = lMusic;
    else if (quality == MiddleQuality) data = mMusic;
    else if (quality == HighQuality) data = hMusic;
    else data = 0;

    return data ? data->getUrl() : QString();
}

int MusicInfo::fileSize(Quality quality) const
{
    MusicData* data;

    if (quality == LowQuality) data = lMusic;
    else if (quality == MiddleQuality) data = mMusic;
    else if (quality == HighQuality) data = hMusic;
    else data = 0;

    return data ? data->size : 0;
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
    mCurrentReply->setProperty("query", "data");
    connect(mCurrentReply, SIGNAL(finished()), SLOT(requestFinished()), Qt::QueuedConnection);

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
    mCurrentReply->setProperty("query", "recommend");
    mCurrentReply->setProperty("reload", true);
    connect(mCurrentReply, SIGNAL(finished()), SLOT(requestFinished()), Qt::QueuedConnection);

    mLastError = 0;
    emit loadingChanged();
}

MusicInfo* MusicFetcher::dataAt(const int &index) const
{
    if (index >= 0 && index < mDataList.size())
        return mDataList.at(index);
    else
        return 0;
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

    if (mCurrentReply->property("reload").toBool() && !mDataList.isEmpty()) {
        qDeleteAll(mDataList);
        mDataList.clear();
        emit dataChanged();
    }

    QVariantMap resp = mParser->parse(mCurrentReply->readAll()).toMap();
    mLastError = resp.value("code", -1).toInt();
    if (mLastError != 200) {
        emit loadingChanged();
        return;
    }
    mLastError = 0;

    bool changed = false;
    QVariantList list = resp.value(mCurrentReply->property("query").toString()).toList();
    foreach (const QVariant item, list) {
        MusicInfo* data = createDataFromMap(item);
        if (data) {
            changed = true;
            mDataList.append(data);
        }
    }
    if (changed)
        emit dataChanged();

    emit loadingChanged();
}

MusicInfo* MusicFetcher::createDataFromMap(const QVariant &data)
{
    if (data.isNull() || !data.canConvert(QVariant::Map))
        return 0;

    MusicInfo* result = new MusicInfo(this);
    const QVariantMap& map = data.toMap();

    result->starred = map.value("starred").toBool();
    result->name = map.value("name").toString();
    result->id = map.value("id").toInt();
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

    return result;
}
