#include "musiccollector.h"

#include <QDeclarativeView>
#include <QDeclarativeEngine>
#include <QNetworkAccessManager>
#include <QNetworkReply>

#include "qjson/parser.h"

#include "userconfig.h"
#include "musicfetcher.h"

enum {
    OperationNone,
    OperationCollectMusic,
    OperationRemoveCollection,
    OperationLoadPid,
    OperationLoadPlaylist
};

static const char* ApiBaseUrl = "http://music.163.com/api";
static const char* KeyOperation = "operation";

MusicCollector::MusicCollector(QDeclarativeView *parent) :
    QObject(parent), caller(parent), manager(0), parser(new QJson::Parser),
    playlistId(0), nextOperation(OperationNone)
{
}

MusicCollector::~MusicCollector()
{
    delete parser;
}

bool MusicCollector::isCollected(const QString &id) const
{
    return idList.contains(id.toInt());
}

void MusicCollector::collectMusic(const QString &id)
{
    if (id.toInt() == 0) return;

    if (playlistId == 0) {
        nextOperation = OperationCollectMusic;
        operatingId = id;

        if (!currentReply || currentReply->property(KeyOperation).toInt() != OperationLoadPid) {
            refresh();
        }

        return;
    }

    if (currentReply && currentReply->isRunning())
        currentReply->abort();

    QNetworkRequest req;
    req.setUrl(QString(ApiBaseUrl).append("/v1/playlist/manipulate/tracks"));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

    QByteArray postData;
    postData.append("trackIds=").append(QString("[\"%1\"]").arg(id).toAscii().toPercentEncoding());
    postData.append("&pid=").append(QByteArray::number(playlistId));
    postData.append("&op=add");
    postData.append("&imme=true");

    checkNAM();

    currentReply = manager->post(req, postData);
    currentReply->setProperty(KeyOperation, OperationCollectMusic);
    connect(currentReply, SIGNAL(finished()), SLOT(requestFinished()), Qt::QueuedConnection);

    emit loadingChanged();
}

void MusicCollector::removeCollection(const QString &id)
{
    if (id.toInt() == 0) return;

    if (playlistId == 0) {
        nextOperation = OperationRemoveCollection;
        operatingId = id;

        if (!currentReply || currentReply->property(KeyOperation).toInt() != OperationLoadPid) {
            refresh();
        }

        return;
    }

    if (currentReply && currentReply->isRunning())
        currentReply->abort();

    QNetworkRequest req;
    req.setUrl(QString(ApiBaseUrl).append("/playlist/manipulate/tracks"));
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/x-www-form-urlencoded");

    QByteArray postData;
    postData.append("trackIds=").append(QString("[%1]").arg(id).toAscii().toPercentEncoding());
    postData.append("&pid=").append(QByteArray::number(playlistId));
    postData.append("&op=del");

    checkNAM();

    currentReply = manager->post(req, postData);
    currentReply->setProperty(KeyOperation, OperationRemoveCollection);
    connect(currentReply, SIGNAL(finished()), SLOT(requestFinished()), Qt::QueuedConnection);

    emit loadingChanged();
}

void MusicCollector::refresh()
{
    QString uid = UserConfig::Instance()->getSetting(UserConfig::KeyUserId).toString();
    if (uid.isEmpty())
        return;

    if (currentReply && currentReply->isRunning())
        currentReply->abort();

    QUrl url(QString(ApiBaseUrl).append("/user/playlist/"));
    url.addEncodedQueryItem("offset", "0");
    url.addEncodedQueryItem("limit", "1000");
    url.addEncodedQueryItem("uid", uid.toAscii());

    checkNAM();

    currentReply = manager->get(QNetworkRequest(url));
    currentReply->setProperty(KeyOperation, OperationLoadPid);
    connect(currentReply, SIGNAL(finished()), SLOT(requestFinished()), Qt::QueuedConnection);

    emit loadingChanged();
}

void MusicCollector::loadList()
{
    if (playlistId == 0) {
        if (nextOperation == OperationNone) {
            nextOperation = OperationLoadPlaylist;
            operatingId.clear();
        }

        if (!currentReply || currentReply->property(KeyOperation).toInt() != OperationLoadPid) {
            refresh();
        }

        return;
    }

    if (currentReply && currentReply->isRunning())
        currentReply->abort();

    QUrl url(QString(ApiBaseUrl).append("/v2/playlist/detail"));
    url.addEncodedQueryItem("id", QByteArray::number(playlistId));
    url.addEncodedQueryItem("t", "-1");
    url.addEncodedQueryItem("n", "1000");
    url.addEncodedQueryItem("s", "0");

    checkNAM();

    currentReply = manager->get(QNetworkRequest(url));
    currentReply->setProperty(KeyOperation, OperationLoadPlaylist);
    connect(currentReply, SIGNAL(finished()), SLOT(requestFinished()), Qt::QueuedConnection);

    emit loadingChanged();
}

void MusicCollector::loadFromFetcher(MusicFetcher *fetcher)
{
    if (currentReply) {
        if (currentReply->isRunning())
            currentReply->abort();

        currentReply = 0;
        emit loadingChanged();
    }

    idList.clear();
    for (int i = 0; i < fetcher->count(); i++)
        idList.append(fetcher->dataAt(i)->musicId().toInt());

    emit dataChanged();
}

bool MusicCollector::loading() const
{
    return currentReply && currentReply->isRunning();
}

void MusicCollector::requestFinished()
{
    sender()->deleteLater();
    if (currentReply != sender())
        return;

    emit loadingChanged();

    int nextOpt = nextOperation;
    QString optId = operatingId;

    nextOperation = OperationNone;
    operatingId.clear();

    if (currentReply->error() != QNetworkReply::NoError)
        return;

    QVariantMap resp = parser->parse(currentReply->readAll()).toMap();
    if (resp.value("code", -1).toInt() != 200)
        return;

    int opt = currentReply->property(KeyOperation).toInt();
    if (opt == OperationLoadPid) {
        foreach (const QVariant& playlist, resp.value("playlist").toList()) {
            QVariantMap map = playlist.toMap();
            if (map.value("specialType").toInt() == 5) {
                playlistId = map.value("id").toInt();
                break;
            }
        }
        if (playlistId == 0)
            return;

        if (nextOpt == OperationCollectMusic)
            collectMusic(optId);
        else if (nextOpt == OperationRemoveCollection)
            removeCollection(optId);
        else
            loadList();
    }
    else if (opt == OperationLoadPlaylist) {
        idList.clear();
        QVariantList tracks = resp.value("playlist").toMap().value("trackIds").toList();
        foreach (const QVariant& track, tracks) {
            idList.append(track.toMap().value("id").toInt());
        }
        emit dataChanged();
    }
    else if (opt == OperationCollectMusic || opt == OperationRemoveCollection) {
        loadList();
    }
}

void MusicCollector::checkNAM()
{
    if (!manager)
        manager = caller->engine()->networkAccessManager();
}
