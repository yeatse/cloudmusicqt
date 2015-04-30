#include "musicfetcher.h"

#include <QtDeclarative>
#include <QDeclarativeView>
#include <QDeclarativeEngine>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

#include "qjson/parser.h"

const char* ApiBaseUrl = "http://music.163.com/api";

MusicData::MusicData(QObject *parent) : QObject(parent)
{
}

MusicFetcher::MusicFetcher(QObject *parent) : QObject(parent),
    mNetworkAccessManager(0), mParser(new QJson::Parser),
    isComponentComplete(false)
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
    connect(mCurrentReply, SIGNAL(finished()), SLOT(requestFinished()));

    emit loadingChanged();
}

MusicData* MusicFetcher::dataAt(const int &index) const
{
    if (index >= 0 && index < mDataList.size())
        return mDataList.at(index);
    else
        return 0;
}

int MusicFetcher::count() const
{
    return mDataList.size();
}

bool MusicFetcher::loading() const
{
    return mCurrentReply && mCurrentReply->isRunning();
}

void MusicFetcher::requestFinished()
{
    emit loadingChanged();
    sender()->deleteLater();
    if (mCurrentReply != sender() || mCurrentReply->error() != QNetworkReply::NoError)
        return;

    if (mCurrentReply->property("reload").toBool() && !mDataList.isEmpty()) {
        qDeleteAll(mDataList);
        mDataList.clear();
        emit dataChanged();
    }

    QVariantMap resp = mParser->parse(mCurrentReply->readAll()).toMap();
    if (resp.value("code").toInt() != 200)
        return;

    bool changed = false;
    QVariantList list = resp.value(mCurrentReply->property("query").toString()).toList();
    foreach (const QVariant item, list) {
        MusicData* data = createDataFromMap(item);
        if (data) {
            changed = true;
            mDataList.append(data);
        }
    }
    if (changed)
        emit dataChanged();
}

MusicData* MusicFetcher::createDataFromMap(const QVariant &data)
{
    if (data.isNull() || !data.canConvert(QVariant::Map))
        return 0;

    MusicData* result = new MusicData(this);
    QVariantMap map = data.toMap();
    return result;
}
