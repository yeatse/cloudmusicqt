#include "lyricloader.h"

#include <QFile>
#include <QTextStream>

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>

#include <QtDeclarative>
#include <QDebug>

#include "qjson/parser.h"

class LyricLine
{
public:
    LyricLine():time(0){}
    LyricLine(int time, QString text):time(time), text(text){}

    int time;
    QString text;
};

LyricLoader::LyricLoader(QObject *parent) : QObject(parent),
    parser(new QJson::Parser), manager(0), isComponentComplete(false)
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
    if (!isComponentComplete) return;

    reset();
    QUrl url("http://music.163.com/api/song/lyric");
    url.addEncodedQueryItem("os", "pc");
    url.addEncodedQueryItem("id", musicId.toAscii());
    url.addEncodedQueryItem("lv", "-1");
    url.addEncodedQueryItem("kv", "-1");
    url.addEncodedQueryItem("tv", "-1");

    reply = manager->get(QNetworkRequest(url));
    connect(reply, SIGNAL(finished()), SLOT(requestFinished()), Qt::QueuedConnection);
    emit loadingChanged();
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

int LyricLoader::getLineByPosition(const int &millisec, const int &startPos) const
{
    int result = qBound(0, startPos, lrcLines.size());
    while (result < lrcLines.size()) {
        if (lrcLines.at(result)->time > millisec)
            break;

        result++;
    }
    return result - 1;
}

QStringList LyricLoader::lyric() const
{
    QStringList list;
    foreach (LyricLine* line, lrcLines)
        list.append(line->text);
    return list;
}

bool LyricLoader::loading() const
{
    return reply && reply->isRunning();
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
        qDeleteAll(lrcLines);
        lrcLines.clear();
        emit lyricChanged();
    }
}

bool LyricLoader::processContent(const QString &content)
{
    qDeleteAll(lrcLines);
    lrcLines.clear();

    const QRegExp rx("\\[(\\d+):(\\d+(\\.\\d+)?)\\]");

    int pos = rx.indexIn(content);
    if (pos == -1) {
        QStringList list = content.split('\n', QString::SkipEmptyParts);
        foreach (QString line, list)
            lrcLines.append(new LyricLine(0, line));
    }
    else {
        int lastPos = pos + rx.matchedLength();
        int time = (rx.cap(1).toInt() * 60 + rx.cap(2).toDouble()) * 1000;
        while (true) {
            pos = rx.indexIn(content, lastPos);
            if (pos == -1) {
                lrcLines.append(new LyricLine(time, content.mid(lastPos).trimmed()));
                break;
            }
            lrcLines.append(new LyricLine(time, content.mid(lastPos, pos - lastPos).trimmed()));
            lastPos = pos + rx.matchedLength();
            time = (rx.cap(1).toInt() * 60 + rx.cap(2).toDouble()) * 1000;
        }
    }

    emit lyricChanged();

    return !lrcLines.isEmpty();
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
