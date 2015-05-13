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

    QString id;
    QString name;
    QString artist;
    Status status;
    int progress;
    int size;

    QString remoteUrl;
    QString fileName;
    int errcode;

    QVariant rawData;
};

class MusicDownloadTask;

class MusicDownloader : public QObject
{
    Q_OBJECT
    DECLARE_SINGLETON(MusicDownloader)
    Q_PROPERTY(QString targetDir READ targetDir WRITE setTargetDir NOTIFY targetDirChanged)
    Q_PROPERTY(int quality READ quality WRITE setQuality NOTIFY qualityChanged)
public:
    Q_INVOKABLE void addTask(MusicInfo* item);

    Q_INVOKABLE void pause(const QString& id = QString());
    Q_INVOKABLE void resume(const QString& id = QString());
    Q_INVOKABLE void cancel(const QString& id = QString());
    Q_INVOKABLE void retry(const QString& id = QString());

    QString targetDir() const;
    void setTargetDir(const QString& dir);

    int quality() const;
    void setQuality(const int& quality);

signals:
    void targetDirChanged();
    void qualityChanged();

    void dataChanged();
    void statusChanged(MusicDownloadItem* task);

private slots:
    void startNextTask();
    void slotDataChanged();
    void slotTaskFinished();

private:
    MusicDownloader();
    MusicDownloadItem* createItemFromInfo(MusicInfo* info);
    QString getSaveFileName(MusicDownloadItem* item);

private:
    QList<MusicDownloadTask*> runningTasks;

    int mQuality;
    QString mTargetDir;
};

#endif // MUSICDOWNLOADER_H
