#include "musicdownloadmodel.h"

#include "musicdownloader.h"

MusicDownloadModel::MusicDownloadModel(QObject *parent) :
    QAbstractListModel(parent)
{
    QHash<int, QByteArray> names;
    names[IdRole] = "id";
    names[NameRole] = "name";
    names[ArtistRole] = "artist";
    names[StatusRole] = "status";
    names[ProgressRole] = "progress";
    names[SizeRole] = "size";
    setRoleNames(names);
    refresh();

    connect(MusicDownloader::Instance(), SIGNAL(statusChanged(MusicDownloadItem*)), SLOT(onStatusChanged(MusicDownloadItem*)));
}

MusicDownloadModel::~MusicDownloadModel()
{
    qDeleteAll(mDataList);
}

int MusicDownloadModel::rowCount(const QModelIndex &parent) const
{
    Q_UNUSED(parent)
    return mDataList.size();
}

QVariant MusicDownloadModel::data(const QModelIndex &index, int role) const
{
    const int row = index.row();
    if (row < 0 || row >= mDataList.size())
        return QVariant();

    const MusicDownloadItem* ptr = mDataList.at(row);
    switch (role)
    {
    case IdRole: return ptr->id;
    case NameRole: return ptr->name;
    case ArtistRole: return ptr->artist;
    case StatusRole: return ptr->status;
    case ProgressRole: return ptr->progress;
    case SizeRole: return ptr->size;
    default: return QVariant();
    }
}

void MusicDownloadModel::onStatusChanged(MusicDownloadItem *task)
{
    for (int i = 0; i < mDataList.size(); i++) {
        MusicDownloadItem* myData = mDataList.at(i);
        if (myData->id == task->id) {
            myData->status = task->status;
            myData->progress = task->progress;
            myData->size = task->size;
            emit dataChanged(index(i), index(i));
            break;
        }
    }
}

void MusicDownloadModel::refresh()
{
    beginResetModel();
    qDeleteAll(mDataList);
    mDataList.clear();
    mDataList << MusicDownloader::Instance()->getAllDownloadData();
    endResetModel();
}
