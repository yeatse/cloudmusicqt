#ifndef BLURREDITEM_H
#define BLURREDITEM_H

#include <QDeclarativeItem>

class BlurredItem : public QDeclarativeItem
{
    Q_OBJECT
    Q_PROPERTY(QDeclarativeItem* source READ source WRITE setSource NOTIFY sourceChanged)
public:
    explicit BlurredItem(QDeclarativeItem *parent = 0);

    QDeclarativeItem* source() const;
    void setSource(QDeclarativeItem* source);

    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *);

    Q_INVOKABLE void refresh();

signals:
    void sourceChanged();

protected:
    void componentComplete();

private:
    QDeclarativeItem* mSource;
    QPixmap mPixmap;
};

#endif // BLURREDITEM_H
