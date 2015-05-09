#ifndef MUSICDOWNLOADDATABASE_H
#define MUSICDOWNLOADDATABASE_H

#include <QObject>
#include <QSqlDatabase>
#include "singletonbase.h"

class MusicDownloadDatabase : public QObject
{
    Q_OBJECT
public:
    explicit MusicDownloadDatabase(QObject *parent = 0);

    bool containsRecord(const QString& musicId);

private:
    void initDatabase();
    void createTable();

    int databaseVersion();
    bool setDatabaseVersion(const int& version);

private:
    QSqlDatabase db;
};

class MusicDownloadStatusModel
{
    Q_OBJECT
};

#endif // MUSICDOWNLOADDATABASE_H
