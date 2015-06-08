#include "harmattanbackgroundprovider.h"

#include <QDeclarativeItem>
#include <QPainter>
#include <QStyleOptionGraphicsItem>

HarmattanBackgroundProvider::HarmattanBackgroundProvider() :
    QObject(0), QDeclarativeImageProvider(QDeclarativeImageProvider::Pixmap)
{
}

QT_BEGIN_NAMESPACE
extern Q_GUI_EXPORT void qt_blurImage( QPainter *p, QImage &blurImage, qreal radius, bool quality, bool alphaOnly, int transposed = 0 );
QT_END_NAMESPACE

QPixmap HarmattanBackgroundProvider::requestPixmap(const QString &id, QSize *size, const QSize &requestedSize)
{
    Q_UNUSED(id)

    if (mPixmap.isNull() && mSource && mSource->width() >= 1 && mSource->height() >= 1) {
        QImage image = QImage((int)mSource->width(), (int)mSource->height(), QImage::Format_ARGB32);
        QImage srcImg = image;
        {
            QPainter p(&srcImg);
            QStyleOptionGraphicsItem option;
            mSource->paint(&p, &option, 0);
        }
        QPainter p(&image);
        qt_blurImage(&p, srcImg, 50, true, false);
        p.fillRect(image.rect(), QColor(0, 0, 0, 160));
        mPixmap = QPixmap::fromImage(image);
    }

    *size = mPixmap.size();
    if (requestedSize.width() > 0 || requestedSize.height() > 0) {
        if (requestedSize.width() == 0)
            return mPixmap.scaledToHeight(requestedSize.height(), Qt::SmoothTransformation);
        else if (requestedSize.height() == 0)
            return mPixmap.scaledToWidth(requestedSize.width(), Qt::SmoothTransformation);
        else
            return mPixmap.scaled(requestedSize, Qt::IgnoreAspectRatio, Qt::SmoothTransformation);
    }

    return mPixmap;
}

void HarmattanBackgroundProvider::refresh(QDeclarativeItem *item)
{
    if (mSource != item) {
        mSource = item;
        mPixmap = QPixmap();
    }
}
