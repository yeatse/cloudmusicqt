#include "blurreditem.h"

#include <QPainter>
#include <QDebug>

BlurredItem::BlurredItem(QDeclarativeItem *parent) :
    QDeclarativeItem(parent), mSource(0)
{
    setFlag(ItemHasNoContents, false);
}

QDeclarativeItem* BlurredItem::source() const
{
    return mSource;
}

void BlurredItem::setSource(QDeclarativeItem *source)
{
    if (mSource != source) {
        mSource = source;
        emit sourceChanged();

        if (isComponentComplete())
            refresh();
    }
}

QT_BEGIN_NAMESPACE
extern Q_GUI_EXPORT void qt_blurImage( QPainter *p, QImage &blurImage, qreal radius, bool quality, bool alphaOnly, int transposed = 0 );
QT_END_NAMESPACE

void BlurredItem::paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *)
{
    if (mPixmap.isNull() && mSource && mSource->width() >= 1 && mSource->height() >= 1) {
        QImage image = QImage((int)mSource->width(), (int)mSource->height(), QImage::Format_ARGB32);
        QImage srcImg = image;
        {
            QPainter p(&srcImg);
            mSource->paint(&p, option, 0);
        }
        QPainter p(&image);
        qt_blurImage(&p, srcImg, 50, true, false);
        p.fillRect(image.rect(), QColor(0, 0, 0, 160));
        mPixmap = QPixmap::fromImage(image);
    }

    if (mPixmap.isNull())
        painter->fillRect(boundingRect(), Qt::transparent);
    else
        painter->drawPixmap(boundingRect().toRect(), mPixmap);
}

void BlurredItem::refresh()
{
    mPixmap = QPixmap();
    update();
}

void BlurredItem::componentComplete()
{
    QDeclarativeItem::componentComplete();
    if (mSource)
        refresh();
}
