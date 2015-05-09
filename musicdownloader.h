#ifndef MUSICDOWNLOADER_H
#define MUSICDOWNLOADER_H

#include <QObject>

class MusicDownloader : public QObject
{
    Q_OBJECT
public:
    explicit MusicDownloader(QObject *parent = 0);
    
signals:
    
public slots:
    
};

#endif // MUSICDOWNLOADER_H
