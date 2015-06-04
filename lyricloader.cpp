#include "lyricloader.h"

#include <QFile>
#include <QStringList>

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
    QFile file(fileName);
    return file.size() && file.open(QIODevice::ReadOnly) && processContent(file.readAll());
}

void LyricLoader::loadFromMusicId(const QString &musicId)
{
    reset();

}

QStringList LyricLoader::lyric() const
{

}

bool LyricLoader::loading() const
{
    return reply && reply->isRunning();
}

int LyricLoader::lineIndex() const
{

}

void LyricLoader::reset()
{
    rawData.clear();
    lrcLines.clear();
    currentIndex = -1;
}

void LyricLoader::processContent(const QString &content)
{
    reset();
    rawData = content;
}
