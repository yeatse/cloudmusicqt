#ifndef MUSICCOLLECTOR_H
#define MUSICCOLLECTOR_H

#include <QObject>
#include <QPointer>

class QDeclarativeView;
class QNetworkAccessManager;
class QNetworkReply;

class MusicFetcher;

namespace QJson { class Parser; }

class MusicCollector : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ loading NOTIFY loadingChanged)
public:
    explicit MusicCollector(QDeclarativeView* parent);
    ~MusicCollector();

    Q_INVOKABLE bool isCollected(const QString& id) const;

    Q_INVOKABLE void collectMusic(const QString& id);
    Q_INVOKABLE void removeCollection(const QString& id);

    Q_INVOKABLE void refresh();
    Q_INVOKABLE void loadList();

    Q_INVOKABLE void loadFromFetcher(MusicFetcher* fetcher);

    bool loading() const;

signals:
    void dataChanged();
    void loadingChanged();

private slots:
    void requestFinished();

private:
    void checkNAM();

private:
    QDeclarativeView* caller;
    QNetworkAccessManager* manager;
    QJson::Parser* parser;

    QPointer<QNetworkReply> currentReply;

    int playlistId;
    QList<int> idList;

    int nextOperation;
    QString operatingId;
};

#endif // MUSICCOLLECTOR_H
