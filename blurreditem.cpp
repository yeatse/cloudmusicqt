#include "blurreditem.h"

#include <QPainter>

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
    if (mImage.isNull() && mSource && mSource->width() >= 1 && mSource->height() >= 1) {
        mImage = QImage((int)mSource->width(), (int)mSource->height(), QImage::Format_ARGB32);
        QPainter p(&mImage);
        mSource->paint(&p, option, 0);

        QImage copy = mImage;
        qt_blurImage(&p, copy, 50, true, false);

        p.fillRect(mImage.rect(), QColor(0, 0, 0, 160));
    }

    if (mImage.isNull())
        painter->fillRect(boundingRect(), Qt::transparent);
    else
        painter->drawImage(boundingRect(), mImage);
}

void BlurredItem::refresh()
{
    mImage = QImage();
    update();
}

void BlurredItem::componentComplete()
{
    QDeclarativeItem::componentComplete();
    if (mSource)
        refresh();
}
