#ifndef HARMATTANBACKGROUNDPROVIDER_H
#define HARMATTANBACKGROUNDPROVIDER_H

#include <QObject>
#include <QDeclarativeImageProvider>
#include <QPointer>

class QDeclarativeItem;
class HarmattanBackgroundProvider : public QObject, public QDeclarativeImageProvider
{
    Q_OBJECT
public:
    explicit HarmattanBackgroundProvider();
    QPixmap requestPixmap(const QString &id, QSize *size, const QSize &requestedSize);

    Q_INVOKABLE void refresh(QDeclarativeItem* item);

private:
    QPointer<QDeclarativeItem> mSource;
    QPixmap mPixmap;
};

#endif // HARMATTANBACKGROUNDPROVIDER_H
