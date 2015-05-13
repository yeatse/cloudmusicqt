#include "musicdownloader.h"

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QThread>
#include <QTimer>
#include <QDesktopServices>
#include <QDir>
#include <QFileInfo>

#include "musicdownloaddatabase.h"
#include "musicfetcher.h"
#include "userconfig.h"

static const int MaxSimultaneousTasks = 1;

class MusicDownloadTask : public QObject
{
    Q_OBJECT
public:
    MusicDownloadTask(MusicDownloader* caller, MusicDownloadItem* task);
    ~MusicDownloadTask();

signals:
    void finished();
    void dataChanged();
    void aborted();

public slots:
    void start();

private slots:
    void downloadReadyRead();
    void downloadProgress(qint64 bytesReceived, qint64 bytesTotal);

private:
    MusicDownloader* caller;
    MusicDownloadItem* task;
    QNetworkAccessManager* manager;

    friend class MusicDownloader;
};

MusicDownloadTask::MusicDownloadTask(MusicDownloader *caller, MusicDownloadItem *task)
    : QObject(0), caller(caller), task(task), manager(0)
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
    if (task->status == MusicDownloadItem::Paused) {
        emit finished();
        return;
    }

    task->errcode = 0;
    task->status = MusicDownloadItem::Running;

    emit dataChanged();

    if (!manager)
        manager = new QNetworkAccessManager(this);

    QEventLoop loop;

    QNetworkReply* reply = manager->get(QNetworkRequest(QUrl(task->remoteUrl)));
    connect(reply, SIGNAL(readyRead()), SLOT(downloadReadyRead()));
    connect(reply, SIGNAL(downloadProgress(qint64,qint64)), SLOT(downloadProgress(qint64,qint64)));
    connect(reply, SIGNAL(finished()), &loop, SLOT(quit()));
    connect(this, SIGNAL(aborted()), &loop, SLOT(quit()));

    loop.exec();
}

void MusicDownloadTask::downloadReadyRead()
{

}

void MusicDownloadTask::downloadProgress(qint64 bytesReceived, qint64 bytesTotal)
{

}

MusicDownloader::MusicDownloader() : QObject(), mQuality(0)
{
    UserConfig* cfg = UserConfig::Instance();
    mQuality = cfg->getSetting(UserConfig::KeyDownloadQuality, MusicInfo::HighQuality).toInt();
    mTargetDir = cfg->getSetting(UserConfig::KeyDownloadDirectory,
                                 QDesktopServices::storageLocation(QDesktopServices::MusicLocation)).toString();

    QDir dir(mTargetDir);
    if (!dir.exists())
        dir.mkpath(dir.absolutePath());
}

void MusicDownloader::addTask(MusicInfo *item)
{
    MusicDownloadDatabase* db = MusicDownloadDatabase::Instance();
    if (db->containsRecord(item->id))
        return;

    MusicDownloadItem* i = createItemFromInfo(item);
    db->addRecord(i);

    QTimer::singleShot(0, this, SLOT(startNextTask()));
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
            QTimer::singleShot(0, task, SIGNAL(aborted()));
        }
    }
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
}

void MusicDownloader::cancel(const QString &id)
{
    MusicDownloadDatabase::Instance()->cancel(id);
    foreach (MusicDownloadTask* task, runningTasks) {
        MusicDownloadItem* item = task->task;
        if (id.isEmpty() || id == item->id) {
            item->status = MusicDownloadItem::Paused;
            QTimer::singleShot(0, task, SIGNAL(aborted()));
        }
    }
}

void MusicDownloader::retry(const QString &id)
{
    MusicDownloadDatabase::Instance()->retry(id);
    foreach (MusicDownloadTask* task, runningTasks) {
        MusicDownloadItem* item = task->task;
        if (item->status != MusicDownloadItem::Error)
            continue;

        if (id.isEmpty() || id == item->id) {
            item->status = MusicDownloadItem::Pending;
        }
    }
    QTimer::singleShot(0, this, SLOT(startNextTask()));
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
        MusicDownloadDatabase::Instance()->updateRecord(task->task);
}

void MusicDownloader::slotTaskFinished()
{
    MusicDownloadTask* task = qobject_cast<MusicDownloadTask*>(sender());
    if (!task)
        return;

    MusicDownloadDatabase::Instance()->updateRecord(task->task);
    runningTasks.removeAll(task);
    task->deleteLater();

    QTimer::singleShot(0, this, SLOT(startNextTask()));
}

MusicDownloadItem* MusicDownloader::createItemFromInfo(MusicInfo *info)
{
    MusicDownloadItem* item = new MusicDownloadItem;
    item->id = info->musicId();
    item->name = info->musicName();
    item->artist = info->artistsDisplayName();
    item->status = MusicDownloadItem::Pending;
    item->progress = 0;
    item->size = info->fileSize(mQuality);
    item->remoteUrl = info->getUrl(mQuality);
    item->fileName = getSaveFileName(item);
    item->errcode = 0;
    item->rawData = info->rawData;
    return item;
}

QString MusicDownloader::getSaveFileName(MusicDownloadItem *item)
{
    QString path = mTargetDir + QDir::separator()
            + item->artist + " - " + item->name + "." + QFileInfo(item->remoteUrl).suffix();

    return QDir::cleanPath(path);
}

#include "musicdownloader.moc"
