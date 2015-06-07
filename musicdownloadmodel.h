#ifndef MUSICDOWNLOADMODEL_H
#define MUSICDOWNLOADMODEL_H

#include <QObject>
#include <QAbstractListModel>

class MusicDownloadItem;

class MusicDownloadModel : public QAbstractListModel
{
    Q_OBJECT
    Q_ENUMS(DataType)
    Q_PROPERTY(DataType dataType READ dataType WRITE setDataType NOTIFY dataTypeChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY loadFinished)
public:
    enum DataRoles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        ArtistRole,
        StatusRole,
        ProgressRole,
        SizeRole,
        ErrCodeRole
    };

    enum DataType {
        ProcessingData, CompletedData
    };

    explicit MusicDownloadModel(QObject *parent = 0);
    ~MusicDownloadModel();

    DataType dataType() const;
    void setDataType(const DataType& type);

    int rowCount(const QModelIndex &parent) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;

    Q_INVOKABLE int getIndexByMusicId(const QString& musicId) const;

    QList<MusicDownloadItem*> getDataList() const;

public slots:
    void refresh(MusicDownloadItem* item = 0);

signals:
    void loadFinished();
    void dataTypeChanged();

private:
    QList<MusicDownloadItem*> mDataList;
    DataType mDataType;
};

#endif // MUSICDOWNLOADMODEL_H
