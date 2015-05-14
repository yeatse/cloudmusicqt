#ifndef MUSICDOWNLOADMODEL_H
#define MUSICDOWNLOADMODEL_H

#include <QObject>
#include <QAbstractListModel>

class MusicDownloadItem;

class MusicDownloadModel : public QAbstractListModel
{
    Q_OBJECT
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

    explicit MusicDownloadModel(QObject *parent = 0);
    ~MusicDownloadModel();

    int rowCount(const QModelIndex &parent) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;

public slots:
    void refresh(MusicDownloadItem* item = 0);

private:
    QList<MusicDownloadItem*> mDataList;
};

#endif // MUSICDOWNLOADMODEL_H
