#ifndef SLIDERPROXY_H
#define SLIDERPROXY_H
#include <QProxyStyle>

class SliderProxy : public QProxyStyle
{
public:
    int pixelMetric ( PixelMetric metric, const QStyleOption * option = 0, const QWidget * widget = 0 ) const
    {
        switch(metric) {
        case PM_SliderThickness  : return 50;
        case PM_SliderLength     : return 50;
        default                         : return (QProxyStyle::pixelMetric(metric,option,widget));
        }
    }
};

#endif // SLIDERPROXY_H
