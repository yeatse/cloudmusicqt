#include "musicdownloaddatabase.h"

#include <QDir>
#include <QDesktopServices>
#include <QSqlQuery>
#include <QVariant>

#include "musicdownloader.h"

#include "qjson/parser.h"
#include "qjson/serializer.h"

#define TABLE_NAME "tbl_download_record"
#define DB_FILE_NAME "record.db"

enum { DatabaseVersion_V0 };

MusicDownloadDatabase::MusicDownloadDatabase() : QObject(0),
    parser(new QJson::Parser), serializer(new QJson::Serializer)
{
    initDatabase();
}

MusicDownloadDatabase::~MusicDownloadDatabase()
{
    delete parser;
    delete serializer;
}

void MusicDownloadDatabase::initDatabase()
{
    if (!QSqlDatabase::contains(TABLE_NAME)) {
        QDir dir(QDesktopServices::storageLocation(QDesktopServices::DataLocation));
        if (!dir.exists())
            dir.mkpath(dir.absolutePath());

        db = QSqlDatabase::addDatabase("QSQLITE", TABLE_NAME);
        db.setDatabaseName(dir.absoluteFilePath(DB_FILE_NAME));
        db.open();
        createTable();
    }
    else {
        db = QSqlDatabase::database(TABLE_NAME);
    }
}

void MusicDownloadDatabase::createTable()
{
    const char* createTbl =
            "CREATE TABLE IF NOT EXISTS "
            TABLE_NAME
            " ("
            "mid INTEGER NOT NULL,"
            "name VARCHAR(256),"
            "artist VARCHAR(256),"
            "status INTEGER NOT NULL,"
            "progress INTEGER NOT NULL DEFAULT(0),"
            "size INTEGER NOT NULL,"
            "url VARCHAR(256) NOT NULL,"
            "fname VARCHAR(256) NOT NULL,"
            "errcode INTEGER NOT NULL DEFAULT(0),"
            "rawdata BLOB NOT NULL,"
            "addtime TIMESTAMP NOT NULL DEFAULT(datetime('now', 'localtime')),"
            "PRIMARY KEY (mid)"
            ")";

    if (databaseVersion() == DatabaseVersion_V0) {
        db.exec(createTbl);
    }
}

int MusicDownloadDatabase::databaseVersion()
{
    QSqlQuery query("PRAGMA user_version", db);
    return query.exec() && query.first() ? query.value(0).toInt() : -1;
}

bool MusicDownloadDatabase::setDatabaseVersion(const int &version)
{
    QSqlQuery query(QString("PRAGMA user_version = %1").arg(version), db);
    return query.exec();
}

bool MusicDownloadDatabase::containsRecord(const QString &musicId)
{
    QString q("SELECT COUNT(1) FROM %1 WHERE mid = %2");
    QSqlQuery query(q.arg(TABLE_NAME, musicId), db);
    return query.exec() && query.first() && query.value(0).toInt() > 0;
}

bool MusicDownloadDatabase::addRecord(MusicDownloadItem *record)
{
    QString q("INSERT OR REPLACE INTO %1"
              " (mid,name,artist,status,progress,size,url,fname,rawdata) "
              "VALUES (?,?,?,?,?,?,?,?,?)");

    QSqlQuery query(q.arg(TABLE_NAME), db);
    query.addBindValue(record->id);
    query.addBindValue(record->name);
    query.addBindValue(record->artist);
    query.addBindValue(record->status);
    query.addBindValue(record->progress);
    query.addBindValue(record->size);
    query.addBindValue(record->remoteUrl);
    query.addBindValue(record->fileName);
    query.addBindValue(serializer->serialize(record->rawData));

    return query.exec();
}

bool MusicDownloadDatabase::updateRecord(MusicDownloadItem *record)
{
    QString q("UPDATE %1 SET status = %2, progress = %3, size = %4, errcode = %5 "
              "WHERE mid = %6");

    QSqlQuery query(q.arg(TABLE_NAME,
                          QString::number(record->status),
                          QString::number(record->progress),
                          QString::number(record->size),
                          QString::number(record->errcode),
                          record->id),
                    db);

    return query.exec();
}

bool MusicDownloadDatabase::pause(const QString &id)
{
    QString q("UPDATE %1 SET status = %2 WHERE (status = %3 OR status = %4)");
    if (!id.isEmpty())
        q.append(" AND mid = ").append(id);

    QSqlQuery query(q.arg(TABLE_NAME,
                          QString::number(MusicDownloadItem::Paused),
                          QString::number(MusicDownloadItem::Pending),
                          QString::number(MusicDownloadItem::Running)),
                    db);

    return query.exec();
}

bool MusicDownloadDatabase::resume(const QString &id)
{
    QString q("UPDATE %1 SET status = %2 WHERE status = %3");
    if (!id.isEmpty())
        q.append(" AND mid = ").append(id);

    QSqlQuery query(q.arg(TABLE_NAME,
                          QString::number(MusicDownloadItem::Pending),
                          QString::number(MusicDownloadItem::Paused)),
                    db);

    return query.exec();
}

bool MusicDownloadDatabase::cancel(const QString &id)
{
    QString q("DELETE FROM %1 WHERE status != %2");
    if (!id.isEmpty())
        q.append(" AND mid = ").append(id);

    QSqlQuery query(q.arg(TABLE_NAME,
                          QString::number(MusicDownloadItem::Completed)),
                    db);

    return query.exec();
}

bool MusicDownloadDatabase::retry(const QString &id)
{
    QString q("UPDATE %1 SET status = %2 WHERE status = %3");
    if (!id.isEmpty())
        q.append(" AND mid = ").append(id);

    QSqlQuery query(q.arg(TABLE_NAME,
                          QString::number(MusicDownloadItem::Pending),
                          QString::number(MusicDownloadItem::Error)),
                    db);

    return query.exec();
}

QList<MusicDownloadItem*> MusicDownloadDatabase::getAllPendingRecords()
{
    QString q("SELECT * FROM %1 WHERE status = %2");
    QSqlQuery query(q.arg(TABLE_NAME, QString::number(MusicDownloadItem::Pending)),
                    db);
    return buildListFromQuery(query);
}

QList<MusicDownloadItem*> MusicDownloadDatabase::buildListFromQuery(QSqlQuery &query)
{
    QList<MusicDownloadItem*> result;
    if (query.exec()) {
        while (query.next()) {
            result.append(createItemFromQuery(query));
        }
    }
    return result;
}

MusicDownloadItem* MusicDownloadDatabase::createItemFromQuery(QSqlQuery &query)
{
    MusicDownloadItem* result = new MusicDownloadItem;
    result->id = query.value(0).toString();
    result->name = query.value(1).toString();
    result->artist = query.value(2).toString();
    result->status = (MusicDownloadItem::Status)query.value(3).toInt();
    result->progress = query.value(4).toInt();
    result->size = query.value(5).toInt();
    result->remoteUrl = query.value(6).toString();
    result->fileName = query.value(7).toString();
    result->errcode = query.value(8).toInt();
    result->rawData = parser->parse(query.value(9).toByteArray());
    return result;
}
