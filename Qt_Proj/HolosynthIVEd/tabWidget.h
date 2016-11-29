#ifndef TABWIDGET_H
#define TABWIDGET_H

#include <QDialog>
#include <QPushButton>
#include <QLCDNumber>
#include <QTabWidget>
#include <QObject>
#include <QLabel>
#include <QSlider>
#include "sliderproxy.h"

#include <qwt_plot.h>
#include <qwt_plot_curve.h>
#include <qwt_plot_grid.h>
#include <qwt_symbol.h>
#include <qwt_legend.h>

#include "fpga.h"
#include <stdint.h>
#include <QTextEdit>
#include <QComboBox>

#define lcd_width 40
#define lcd_height 30
#define button_width 90
#define button_height 35

class synth1Tab : public QWidget
{
    Q_OBJECT

public:
    FPGA *fpga;
    synth1Tab();
    fileTab *ftab1;
    QSlider *main_slider;
    SliderProxy * aSliderProxy;
    QLabel *osc_label[13];
    QLabel *osc_num_label[4];
    QPushButton *osc_button[12][4];
    QStringList oscLabels;
    QLCDNumber *osc_lcd[12][4];

    QLabel *mat_label[10];
    QLabel *mat_num_label[8];
    QPushButton *mat_button[8][4];
    QStringList matLabels;
    QLCDNumber *mat_lcd[8][4];

    QLabel *env_label[2][5];
    QLabel *env_num_label[4][5];
    QPalette *p_env[5];
    QPushButton *env_button[16][4];
    QStringList envLabels;
    QLCDNumber *env_lcd[16][4];

    QLabel *com_label[7];
    QPalette *p_com;
    QPushButton *com_button[7];
    QStringList comLabels;
    QLCDNumber *com_lcd[7];

    QComboBox *fileloadbox;

    int Addressreg_x,Addressreg_y;
    int val;
    int i, j, xi, xy, z, o;
    int x_offset,y_offset;

public slots:
    void osc_button_pressed(void);
    void mat_button_pressed(void);
    void env_button_pressed(void);
    void com_button_pressed(void);
    void setEnvPlot(int envNr);
    void main_slider_val_change(int value);
    void setLCD(unsigned int RegAddress, int newValue);
    void populate_fileloadbox();

private:
    QLCDNumber *main_lcd;
    QwtPlotCurve *curve[5];
    QwtSymbol *symbol[5];
    QPolygonF points[5];
    QwtPlot *qwtPlotenv[5];
    int Address;
    u_int8_t regvalue;

};

class fileTab : public QWidget
{
    Q_OBJECT


public:
    FPGA *fpga;
    synth1Tab* synthTab;
    fileTab();
    QPushButton *closebutton;
    QPushButton *fileopenbutton;
    QTextEdit *display;

signals:
    void quit_touched(void);

public slots:
    void on_closebutton_pressed();
    void open_file_dialog();
    void readSyxFile(QString filename);

private:
    int Address;
    u_int8_t regvalue;
    QByteArray Buffer;
    unsigned int FileBufferIndex;
};


#endif // TABWIDGET_H
