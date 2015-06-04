#include "lyricloader.h"

#include <QFile>
#include <QStringList>
#include <QTextStream>

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

#include <QtDeclarative>

#include "qjson/parser.h"

LyricLoader::LyricLoader(QObject *parent) : QObject(parent),
    parser(new QJson::Parser), manager(0), currentIndex(-1),
    isComponentComplete(false)
{
}

LyricLoader::~LyricLoader()
{
    delete parser;
}

void LyricLoader::classBegin()
{
    manager = qmlEngine(this)->networkAccessManager();
}

void LyricLoader::componentComplete()
{
    isComponentComplete = true;
}

bool LyricLoader::loadFromFile(const QString &fileName)
{
    reset();
    QFile file(fileName);
    if (file.size() && file.open(QIODevice::ReadOnly)) {
        QTextStream stream(&file);
        return processContent(stream.readAll());
    }
    return false;
}

void LyricLoader::loadFromMusicId(const QString &musicId)
{
    reset();
}

void LyricLoader::saveToFile(const QString &fileName)
{
    if (lrcLines.isEmpty() || rawData.isEmpty())
        return;

    QFile file(fileName);
    if (file.exists() && !file.remove())
        return;

    if (!file.open(QIODevice::WriteOnly))
        return;

    QTextStream stream(&file);
    stream << rawData;
}

QStringList LyricLoader::lyric() const
{
    return lrcLines;
}

bool LyricLoader::loading() const
{
    return reply && reply->isRunning();
}

int LyricLoader::lineIndex() const
{
    return currentIndex;
}

void LyricLoader::reset()
{
    if (reply && reply->isRunning()) {
        reply->abort();
        reply = 0;
        emit loadingChanged();
    }
    else {
        reply = 0;
    }

    rawData.clear();
    if (lrcLines.size()) {
        lrcLines.clear();
        emit lyricChanged();
    }

    if (currentIndex != -1) {
        currentIndex = -1;
        emit lineIndexChanged();
    }
}

bool LyricLoader::processContent(const QString &content)
{
}

void LyricLoader::requestFinished()
{
    sender()->deleteLater();
    if (reply != sender())
        return;

    emit loadingChanged();

    if (reply->error() == QNetworkReply::NoError) {
        QVariantMap resp = parser->parse(reply->readAll()).toMap();
        if (resp.value("code", -1).toInt() == 200) {
            QString lrc = resp.value("lrc").toMap().value("lyric").toString();
            if (processContent(lrc)) {
                emit lyricChanged();
            }
        }
    }
}
