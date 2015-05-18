#ifndef MUSICDOWNLOADDATABASE_H
#define MUSICDOWNLOADDATABASE_H

#include <QObject>
#include <QSqlDatabase>
#include "singletonbase.h"

namespace QJson { class Parser; class Serializer; }

class MusicDownloadItem;

class MusicDownloadDatabase : public QObject
{
    Q_OBJECT
    DECLARE_SINGLETON(MusicDownloadDatabase)
public:
    ~MusicDownloadDatabase();

    bool containsRecord(const QString& musicId);
    bool addRecord(MusicDownloadItem* record);
    bool updateRecord(MusicDownloadItem* record);

    bool pause(const QString& id = QString());
    bool resume(const QString& id = QString());
    bool cancel(const QString& id = QString());
    bool retry(const QString& id = QString());

    bool removeCompletedTask(const QString& id = QString());

    QList<MusicDownloadItem*> getAllRecords();
    QList<MusicDownloadItem*> getAllPendingRecords();

    MusicDownloadItem* getRecord(const QString& musicId);

public slots:
    void freeResource();

private:
    MusicDownloadDatabase();
    void initDatabase();
    void createTable();

    int databaseVersion();
    bool setDatabaseVersion(const int& version);

    QList<MusicDownloadItem*> buildListFromQuery(QSqlQuery& query);
    MusicDownloadItem* createItemFromQuery(QSqlQuery& query);

private:
    QSqlDatabase* db;
    QJson::Parser* parser;
    QJson::Serializer* serializer;
};

#endif // MUSICDOWNLOADDATABASE_H
