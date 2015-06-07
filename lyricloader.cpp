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
    mParser(new QJson::Parser), mNetworkManager(0), mHasTimer(false),
    isComponentComplete(false)
{
}

LyricLoader::~LyricLoader()
{
    delete mParser;
}

void LyricLoader::classBegin()
{
    mNetworkManager = qmlEngine(this)->networkAccessManager();
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
        stream.setCodec("UTF-8");
        stream.setAutoDetectUnicode(true);
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

    mReply = mNetworkManager->get(QNetworkRequest(url));
    connect(mReply, SIGNAL(finished()), SLOT(requestFinished()), Qt::QueuedConnection);
    emit loadingChanged();
}

void LyricLoader::saveToFile(const QString &fileName)
{
    if (mLines.isEmpty() || mRawData.isEmpty())
        return;

    QFile file(fileName);
    if (file.exists() && !file.remove())
        return;

    if (!file.open(QIODevice::WriteOnly))
        return;

    QTextStream stream(&file);
    stream.setCodec("UTF-8");
    stream << mRawData;
}

int LyricLoader::getLineByPosition(const int &millisec, const int &startPos) const
{
    if (!mHasTimer || mLines.isEmpty())
        return -1;

    int result = qBound(0, startPos, mLines.size());
    while (result < mLines.size()) {
        if (mLines.at(result)->time > millisec)
            break;

        result++;
    }
    return result - 1;
}

bool LyricLoader::dataAvailable() const
{
    return !mLines.isEmpty() && !mRawData.isEmpty();
}

QStringList LyricLoader::lyric() const
{
    QStringList list;
    foreach (LyricLine* line, mLines)
        list.append(line->text);
    return list;
}

bool LyricLoader::hasTimer() const
{
    return mHasTimer;
}

bool LyricLoader::loading() const
{
    return mReply && mReply->isRunning();
}

void LyricLoader::reset()
{
    if (mReply && mReply->isRunning()) {
        mReply->abort();
        mReply = 0;
        emit loadingChanged();
    }
    else {
        mReply = 0;
    }

    mRawData.clear();

    if (!mLines.isEmpty()) {
        qDeleteAll(mLines);
        mLines.clear();
        mHasTimer = false;
        emit lyricChanged();
    }
}

bool lyricTimeLessThan(const LyricLine* line1, const LyricLine* line2)
{
    return line1->time < line2->time;
}

bool LyricLoader::processContent(const QString &content)
{
    if (!mLines.isEmpty()) {
        qDeleteAll(mLines);
        mLines.clear();
        mHasTimer = false;
        emit lyricChanged();
    }

    const QRegExp rx("\\[(\\d+):(\\d+(\\.\\d+)?)\\]");

    mRawData = content;
    int pos = rx.indexIn(content);
    if (pos == -1) {
        QStringList list = content.split('\n', QString::SkipEmptyParts);
        foreach (QString line, list)
            mLines.append(new LyricLine(0, line));

        mHasTimer = false;
    }
    else {
        int lastPos = pos + rx.matchedLength();
        QList<int> timeLabels;
        timeLabels << (rx.cap(1).toInt() * 60 + rx.cap(2).toDouble()) * 1000;
        while (true) {
            pos = rx.indexIn(content, lastPos);
            if (pos == -1) {
                QString text = content.mid(lastPos).trimmed();
                foreach (const int& time, timeLabels)
                    mLines.append(new LyricLine(time, text));
                break;
            }
            QString text = content.mid(lastPos, pos - lastPos);
            if (!text.isEmpty()) {
                foreach (const int& time, timeLabels)
                    mLines.append(new LyricLine(time, text.trimmed()));
                timeLabels.clear();
            }
            lastPos = pos + rx.matchedLength();
            timeLabels << (rx.cap(1).toInt() * 60 + rx.cap(2).toDouble()) * 1000;
        }
        qStableSort(mLines.begin(), mLines.end(), lyricTimeLessThan);
        mHasTimer = true;
    }

    if (!mLines.isEmpty()) {
        emit lyricChanged();
        return true;
    }

    return false;
}

void LyricLoader::requestFinished()
{
    sender()->deleteLater();
    if (mReply != sender())
        return;

    if (mReply->error() == QNetworkReply::NoError) {
        QVariantMap resp = mParser->parse(mReply->readAll()).toMap();
        if (resp.value("code", -1).toInt() == 200) {
            QString lrc = resp.value("lrc").toMap().value("lyric").toString();
            if (processContent(lrc)) {
                emit lyricChanged();
            }
        }
    }

    emit loadingChanged();
}
