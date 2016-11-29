#ifndef SYNTH1TAB_H
#define SYNTH1TAB_H
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

#include "filetab.h"
#include "fpga.h"
#include <stdint.h>
#include <QTextEdit>
#include <QComboBox>
#include <QCheckBox>
#include<QMessageBox>

#include <QWidget>
#include "keyboard/widgetKeyBoard.h"
#include "examplemyfocus.h"

#define lcd_width 40
#define lcd_height 30

class synth1Tab : public QWidget
{
    Q_OBJECT

public:
   explicit  synth1Tab(QWidget *parent = 0);
    FPGAFS *fpga;
//    fileTab * ftab1;

//    widgetKeyBoard  *myKeyboard2;
    QLineEdit *filenamelineedit;

    QSlider *main_slider;
    SliderProxy * aSliderProxy;
    QLabel *osc_label[13];
    QLabel *osc_num_label[8];
    QPushButton *osc_button[12][8];
    QStringList oscLabels;
    QLCDNumber *osc_lcd[12][8];

    QLabel *mat_label[18];
    QLabel *mat_num_label[16];
    QPushButton *mat_button[16][8];
    QStringList matLabels;
    QLCDNumber *mat_lcd[16][8];

    QLabel *env_label[2][9];
    QLabel *env_num_label[4][9];
    QPalette *p_env[9];
    QPushButton *env_button[16][9];
    QStringList envLabels;
    QLCDNumber *env_lcd[16][9];

    QLabel *com_label[7];
    QPalette *p_com;
    QPushButton *com_button[7];
    QStringList comLabels;
    QLCDNumber *com_lcd[7];

    QComboBox *fileloadbox;
    QPushButton *synthtolcdbutton;

    QPushButton *presetbutton[10];
    QByteArray PresetBuffer[11];

   QCheckBox *presetlistenCheckBox;

   QPushButton *keyboard2openbutton;
   QPushButton *keyboard2closebutton;

   QByteArray patch_name;

//   QMessageBox msgBox;
//   QMessageBox msgBox2;
//   QDialog *textdialog;
//   QLabel *oklabel;
//   QPushButton *okbutton;

   QPushButton *overwriteButton;
   QPushButton *recallButton;
   QPushButton *saveButton;
   QPushButton *cancelButton;

   QPushButton *renamebutton;

    int Addressreg_x,Addressreg_y;
    int val;
    int xi, xy, z, o;
    int x_offset,y_offset;
    unsigned int cur_save_index;
    u_int8_t active_preset;
    u_int8_t preset_state;
    unsigned int p_size;

signals:
    void keyboard_view(void);
    void keyboard_hide(void);

public slots:
    void synthtolcd(void);
    void setEnvPlot(int envNr);
    void osc_button_pressed(void);
    void mat_button_pressed(void);
    void env_button_pressed(void);
    void com_button_pressed(void);
    void main_slider_val_change(int value);
    void setLCD(unsigned int RegAddress, int newValue);
    void populate_fileloadbox();
    void on_fileloadbox_activated(const QString &file);
    void preset_pressed(void);
    void preset_released(void);
    void overwritebutton_pressed(void);
    unsigned int save_preset_to_array(unsigned int arraynum);
    unsigned int load_preset_from_array(unsigned int arraynum);
    unsigned int save_preset_to_file1(unsigned int arraynum);
    unsigned int save_preset_to_file2(void);
    void readSyxFile(QString filename);
    void write_syx_file(QString filename);

    void filenametext_changed(QString f_name);

    void on_keyboard2openbutton_pressed();
    void on_keyboard2closebutton_pressed();

private:
    QLCDNumber *main_lcd;
    QwtPlotCurve *curve[9];
    QwtSymbol *symbol[9];
    QPolygonF points[9];
    QwtPlot *qwtPlotenv[9];
    QByteArray Buffer;

//    u_int8_t regvalue;

};

#endif // SYNTH1TAB_H
