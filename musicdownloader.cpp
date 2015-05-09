#include "musicdownloader.h"

#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QThread>
#include <QEventLoop>

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

MusicDownloader::MusicDownloader(QObject *parent) :
    QObject(parent)
{
}

#include "musicdownloader.moc"
