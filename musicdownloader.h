#ifndef MUSICDOWNLOADER_H
#define MUSICDOWNLOADER_H

#include <QObject>
#include <QVariant>

#include "singletonbase.h"

class MusicInfo;

class MusicDownloadItem
{
public:
    enum Status {
        Pending, Running, Paused, Completed, Failed
    };

    enum Error {
        NoError, FileIOError, CanceledError, NetworkError, FileRemovedError
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
    Q_PROPERTY(QString targetDir READ targetDir WRITE setTargetDir NOTIFY targetDirChanged)
    Q_PROPERTY(int quality READ quality WRITE setQuality NOTIFY qualityChanged)

public slots:
    void addTask(MusicInfo* info);
    void pause(const QString& id = QString());
    void resume(const QString& id = QString());
    void cancel(const QString& id = QString());
    void retry(const QString& id);
    void removeCompletedTask(const QString& id);

public:
    Q_INVOKABLE bool containsRecord(const QString& id) const;
    Q_INVOKABLE QString getCompletedFile(const QString& id) const;

    QString targetDir() const;
    void setTargetDir(const QString& dir);

    int quality() const;
    void setQuality(const int& quality);

    QList<MusicDownloadItem*> getAllRecords();

signals:
    void targetDirChanged();
    void qualityChanged();
    void dataChanged(MusicDownloadItem* item = 0);

    void downloadCompleted(bool success, QString musicName);

private slots:
    void startNextTask();
    void slotDataChanged();
    void slotTaskFinished();

private:
    MusicDownloader();
    MusicDownloadItem* createItemFromInfo(MusicInfo* info);
    QString getSaveFileName(MusicInfo* info);

private:
    QList<MusicDownloadTask*> runningTasks;

    int mQuality;
    QString mTargetDir;

    DECLARE_SINGLETON(MusicDownloader)
};

#endif // MUSICDOWNLOADER_H
