#include "musicdownloader.h"

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QThread>
#include <QTimer>
#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>
#include <QDebug>

#include "musicdownloaddatabase.h"
#include "musicfetcher.h"
#include "userconfig.h"

static const int MaxSimultaneousTasks = 1;
static const int MaxRedirectCount = 3;

class MusicDownloadTask : public QObject
{
    Q_OBJECT
public:
    MusicDownloadTask(MusicDownloader* caller, MusicDownloadItem* task);
    ~MusicDownloadTask();

signals:
    void finished();
    void dataChanged();

public slots:
    void start();
    void abort();

private slots:
    void downloadReadyRead();
    void downloadProgress(qint64 bytesReceived, qint64 bytesTotal);
    void downloadFinished();

private:
    MusicDownloader* caller;
    MusicDownloadItem* task;

    QNetworkAccessManager* manager;
    QFile* output;
    QPointer<QNetworkReply> reply;
    int startPos;
    int redirectCount;

    friend class MusicDownloader;
};

MusicDownloadTask::MusicDownloadTask(MusicDownloader *caller, MusicDownloadItem *task)
    : QObject(0), caller(caller), task(task), manager(0), output(0),
      startPos(0), redirectCount(0)
{
    QThread* thread = new QThread;
    thread->start(QThread::IdlePriority);

    moveToThread(thread);

    connect(this, SIGNAL(destroyed()), thread, SLOT(quit()));
    connect(thread, SIGNAL(finished()), thread, SLOT(deleteLater()));
}

MusicDownloadTask::~MusicDownloadTask()
{
    delete task;
}

void MusicDownloadTask::start()
{
    if (output) return;

    if (task->status == MusicDownloadItem::Paused) {
        emit finished();
        return;
    }

    output = new QFile(task->fileName, this);
    if (output->exists()) {
        if (output->size() == task->size) {
            task->status = MusicDownloadItem::Completed;
            emit finished();
            return;
        }
        if (!output->remove()) {
            task->status = MusicDownloadItem::Failed;
            task->errcode = MusicDownloadItem::FileIOError;
            emit finished();
            return;
        }
    }

    output->setFileName(task->fileName + ".tmp");
    if (output->exists()) {
        if (task->progress == 0 || task->progress != output->size()) {
            if (!output->remove()) {
                task->status = MusicDownloadItem::Failed;
                task->errcode = MusicDownloadItem::FileIOError;
                emit finished();
                return;
            }
            task->progress = 0;
        }
    }
    else {
        task->progress = 0;
    }

    if (!output->open(QIODevice::WriteOnly | QIODevice::Append)) {
        task->status = MusicDownloadItem::Failed;
        task->errcode = MusicDownloadItem::FileIOError;
        emit finished();
        return;
    }

    task->errcode = 0;
    task->status = MusicDownloadItem::Running;
    startPos = task->progress;

    if (!manager)
        manager = new QNetworkAccessManager(this);

    QNetworkRequest req;
    req.setUrl(task->remoteUrl);
    if (startPos > 0) {
        QByteArray range = "bytes=" + QByteArray::number(startPos) + "-";
        req.setRawHeader("Range", range);
    }

    reply = manager->get(req);
    connect(reply, SIGNAL(readyRead()), SLOT(downloadReadyRead()));
    connect(reply, SIGNAL(downloadProgress(qint64,qint64)), SLOT(downloadProgress(qint64,qint64)));
    connect(reply, SIGNAL(finished()), SLOT(downloadFinished()));

    emit dataChanged();
}

void MusicDownloadTask::abort()
{
    if (reply && reply->isRunning())
        reply->abort();
}

void MusicDownloadTask::downloadReadyRead()
{
    if (output->write(reply->readAll()) < 0) {
        task->status = MusicDownloadItem::Failed;
        task->errcode = MusicDownloadItem::FileIOError;

        if (reply && reply->isRunning()) {
            reply->abort();
        }
    }
}

void MusicDownloadTask::downloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{
    if (task->status != MusicDownloadItem::Running) {
        if (reply && reply->isRunning()) {
            reply->abort();
        }
    }
    else {
        task->progress = startPos + bytesReceived;
        task->size = startPos + bytesTotal;
        emit dataChanged();
    }
}

void MusicDownloadTask::downloadFinished()
{
    reply->deleteLater();
    output->close();

    if (reply->error() == QNetworkReply::OperationCanceledError) {
        if (task->status != MusicDownloadItem::Paused) {
            task->progress = 0;
            output->remove();
        }
        emit finished();
        return;
    }

    if (reply->error() != QNetworkReply::NoError) {
        task->status = MusicDownloadItem::Failed;
        task->errcode = MusicDownloadItem::NetworkError;
        task->progress = 0;
        output->remove();
        emit finished();
        return;
    }

    QUrl redirectUrl = reply->attribute(QNetworkRequest::RedirectionTargetAttribute).toUrl();
    if (!redirectUrl.isEmpty()) {
        if (redirectCount++ > MaxRedirectCount) {
            task->status = MusicDownloadItem::Failed;
            task->errcode = MusicDownloadItem::NetworkError;
            task->progress = 0;
            output->remove();
            emit finished();
        }
        else {
            task->remoteUrl = reply->url().resolved(redirectUrl).toString();
            output->deleteLater();
            output = 0;
            QTimer::singleShot(0, this, SLOT(start()));
        }
        return;
    }

    QFile::remove(task->fileName);
    if (output->rename(task->fileName)) {
        task->status = MusicDownloadItem::Completed;
    }
    else {
        task->status = MusicDownloadItem::Failed;
        task->errcode = MusicDownloadItem::FileIOError;
        task->progress = 0;
        output->remove();
    }
    emit finished();
}

MusicDownloader::MusicDownloader() : QObject(), mQuality(0)
{
    UserConfig* cfg = UserConfig::Instance();
    mQuality = cfg->getSetting(UserConfig::KeyDownloadQuality, MusicInfo::HighQuality).toInt();
    if (mQuality < MusicInfo::LowQuality || mQuality > MusicInfo::HighQuality)
        mQuality = MusicInfo::HighQuality;

    mTargetDir = cfg->getSetting(UserConfig::KeyDownloadDirectory,
                                 QDesktopServices::storageLocation(QDesktopServices::MusicLocation)).toString();
    QDir dir(mTargetDir);
    if (!dir.exists())
        dir.mkpath(dir.absolutePath());
}

void MusicDownloader::addTask(MusicInfo *info)
{
    MusicDownloadDatabase* db = MusicDownloadDatabase::Instance();
    if (db->containsRecord(info->musicId()))
        return;

    QScopedPointer<MusicDownloadItem> item(createItemFromInfo(info));
    db->addRecord(item.data());
    QTimer::singleShot(0, this, SLOT(startNextTask()));

    emit dataChanged();
}

void MusicDownloader::pause(const QString &id)
{
    MusicDownloadDatabase::Instance()->pause(id);
    foreach (MusicDownloadTask* task, runningTasks) {
        MusicDownloadItem* item = task->task;
        if (item->status != MusicDownloadItem::Pending && item->status != MusicDownloadItem::Running)
            continue;

        if (id.isEmpty() || id == item->id) {
            item->status = MusicDownloadItem::Paused;
            QTimer::singleShot(0, task, SLOT(abort()));
        }
    }
    emit dataChanged();
}

void MusicDownloader::resume(const QString &id)
{
    MusicDownloadDatabase::Instance()->resume(id);
    foreach (MusicDownloadTask* task, runningTasks) {
        MusicDownloadItem* item = task->task;
        if (item->status != MusicDownloadItem::Paused)
            continue;

        if (id.isEmpty() || id == item->id) {
            item->status = MusicDownloadItem::Pending;
        }
    }
    QTimer::singleShot(0, this, SLOT(startNextTask()));
    emit dataChanged();
}

void MusicDownloader::cancel(const QString &id)
{
    MusicDownloadDatabase::Instance()->cancel(id);
    foreach (MusicDownloadTask* task, runningTasks) {
        MusicDownloadItem* item = task->task;
        if (id.isEmpty() || id == item->id) {
            item->status = MusicDownloadItem::Failed;
            item->errcode = MusicDownloadItem::CanceledError;
            QTimer::singleShot(0, task, SLOT(abort()));
        }
    }
    emit dataChanged();
}

void MusicDownloader::retry(const QString &id)
{
    QScopedPointer<MusicDownloadItem> item(MusicDownloadDatabase::Instance()->getRecord(id));
    if (!item)
        return;

    cancel(id);
    removeCompletedTask(id);

    QScopedPointer<MusicInfo> info(MusicInfo::fromVariant(item->rawData, -1));
    if (info)
        addTask(info.data());
}

void MusicDownloader::removeCompletedTask(const QString &id)
{
    MusicDownloadDatabase* db = MusicDownloadDatabase::Instance();
    QScopedPointer<MusicDownloadItem> item(db->getRecord(id));
    if (item && item->status == MusicDownloadItem::Completed)
        QFile::remove(item->fileName);
    db->removeCompletedTask(id);
    emit dataChanged();
}

bool MusicDownloader::containsRecord(const QString &id) const
{
    return MusicDownloadDatabase::Instance()->containsRecord(id);
}

QString MusicDownloader::getCompletedFile(const QString &id) const
{
    QScopedPointer<MusicDownloadItem> item(MusicDownloadDatabase::Instance()->getRecord(id));
    return item && item->status == MusicDownloadItem::Completed ? item->fileName : "";
}

QString MusicDownloader::targetDir() const
{
    return mTargetDir;
}

void MusicDownloader::setTargetDir(const QString &dir)
{
    if (mTargetDir != dir) {
        mTargetDir = dir;

        QDir d(dir);
        if (!d.exists())
            d.mkpath(d.absolutePath());

        UserConfig::Instance()->setSetting(UserConfig::KeyDownloadDirectory, dir);

        emit targetDirChanged();
    }
}

int MusicDownloader::quality() const
{
    return mQuality;
}

void MusicDownloader::setQuality(const int &quality)
{
    if (mQuality != quality) {
        mQuality = quality;
        UserConfig::Instance()->setSetting(UserConfig::KeyDownloadQuality, quality);
        emit qualityChanged();
    }
}

QList<MusicDownloadItem*> MusicDownloader::getAllRecords()
{
    QList<MusicDownloadItem*> list = MusicDownloadDatabase::Instance()->getAllRecords();
    foreach (MusicDownloadTask* task, runningTasks) {
        foreach (MusicDownloadItem* item, list) {
            if (item->id == task->task->id) {
                item->status = task->task->status;
                item->errcode = task->task->errcode;
                item->progress = task->task->progress;
                item->size = task->task->size;
                break;
            }
        }
    }
    return list;
}

void MusicDownloader::startNextTask()
{
    if (runningTasks.size() >= MaxSimultaneousTasks)
        return;

    QList<MusicDownloadItem*> list = MusicDownloadDatabase::Instance()->getAllPendingRecords();
    while (runningTasks.size() < MaxSimultaneousTasks && !list.isEmpty()) {
        MusicDownloadTask* task = new MusicDownloadTask(this, list.takeFirst());
        runningTasks.append(task);
        connect(task, SIGNAL(dataChanged()), SLOT(slotDataChanged()));
        connect(task, SIGNAL(finished()), SLOT(slotTaskFinished()));
        QTimer::singleShot(0, task, SLOT(start()));
    }
    qDeleteAll(list);
}

void MusicDownloader::slotDataChanged()
{
    MusicDownloadTask* task = qobject_cast<MusicDownloadTask*>(sender());
    if (task)
        emit dataChanged(task->task);
}

void MusicDownloader::slotTaskFinished()
{
    MusicDownloadTask* task = qobject_cast<MusicDownloadTask*>(sender());
    if (!task)
        return;

    MusicDownloadItem* item = task->task;
    MusicDownloadDatabase::Instance()->updateRecord(item);
    runningTasks.removeAll(task);
    task->deleteLater();

    QTimer::singleShot(0, this, SLOT(startNextTask()));
    emit dataChanged(item);

    if (item->status == MusicDownloadItem::Completed)
        emit downloadCompleted(true, item->name);
    else if (item->status == MusicDownloadItem::Failed)
        emit downloadCompleted(false, item->name);
}

MusicDownloadItem* MusicDownloader::createItemFromInfo(MusicInfo *info)
{
    MusicDownloadItem* item = new MusicDownloadItem;
    item->id = info->musicId();
    item->name = info->musicName();
    item->artist = info->artistsDisplayName();
    item->status = MusicDownloadItem::Pending;
    item->progress = 0;
    item->size = info->fileSize((MusicInfo::Quality)mQuality);
    item->remoteUrl = info->getUrl((MusicInfo::Quality)mQuality);
    item->fileName = getSaveFileName(info);
    item->errcode = 0;
    item->rawData = info->getRawData();
    return item;
}

QString MusicDownloader::getSaveFileName(MusicInfo *info)
{
    QString fileName = info->artistsDisplayName()
            + " - " + info->musicName()
            + "." + info->extension((MusicInfo::Quality)mQuality);
    fileName.replace(QRegExp("[\\\\/:\\*\\?\\\"<>\\|]"), "_");
    QString path = mTargetDir + QDir::separator() + fileName;

    return QDir::cleanPath(path);
}

#include "musicdownloader.moc"
