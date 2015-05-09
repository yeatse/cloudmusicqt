#ifndef MUSICDOWNLOADER_H
#define MUSICDOWNLOADER_H

#include <QObject>

#include "singletonbase.h"

class MusicInfo;

class MusicDownloadItem
{
public:
    enum Status {
        Pending, Running, Paused, Completed, Error
    };

    int id;
    QString name;
    QString artist;
    Status status;
    int progress;
    int size;

    QString remoteUrl;
    QString fileName;
    int errcode;
};

class MusicDownloadTask;

class MusicDownloader : public QObject
{
    Q_OBJECT
    DECLARE_SINGLETON(MusicDownloader)
public:
    Q_INVOKABLE void addTask(MusicInfo* item);

    Q_INVOKABLE void pause(const QString& id = QString());
    Q_INVOKABLE void resume(const QString& id = QString());
    Q_INVOKABLE void cancel(const QString& id = QString());
    Q_INVOKABLE void retry(const QString& id = QString());

    QList<MusicDownloadItem*> getAllDownloadData();

private:
    MusicDownloader();
    QList<MusicDownloadTask*> runningTasks;
};

#endif // MUSICDOWNLOADER_H
