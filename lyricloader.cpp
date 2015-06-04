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

int LyricLoader::getLineByPosition(const int &millisec) const
{
    return 0;
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
    const QRegExp rx("\\[(\\d+):(\\d+(\\.\\d+)?)\\]");
    int pos = 0;
    int time = 0;

    while (true) {
        int p = rx.indexIn(content, pos);
        qDebug() << pos << p;
        lrcLines.append(new LyricLine(time, content.mid(pos, p)));
        if (p == -1)
            break;

        time = int((rx.cap(1).toInt() * 60 + rx.cap(2).toDouble()) * 1000);
        pos = p + rx.matchedLength();
    }

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
