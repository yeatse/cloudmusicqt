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
    case IdRole: return QString::number(ptr->id);
    case NameRole: return ptr->name;
    case ArtistRole: return ptr->artist;
    case StatusRole: return ptr->status;
    case ProgressRole: return ptr->progress;
    case SizeRole: return ptr->size;
    default: return QVariant();
    }
}

void MusicDownloadModel::onDownloadTaskChanged(MusicDownloadItem *task)
{
    foreach (MusicDownloadItem* myData, mDataList) {
        if (myData->id == task->id) {
            myData->name = task->name;
            myData->artist = task->artist;
            myData->status = task->status;
            myData->progress = task->progress;
            myData->size = task->size;
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
