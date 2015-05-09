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
        SizeRole
    };

    explicit MusicDownloadModel(QObject *parent = 0);
    ~MusicDownloadModel();

    int rowCount(const QModelIndex &parent) const;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const;

private slots:
    void onDownloadTaskChanged(MusicDownloadItem* task);
    void refresh();

private:
    QList<MusicDownloadItem*> mDataList;
};

#endif // MUSICDOWNLOADMODEL_H
