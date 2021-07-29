#ifndef FILETAB_H
#define FILETAB_H

#include <QDialog>
#include <QPushButton>
#include <QLCDNumber>
#include <QTabWidget>
#include <QObject>
#include <QLabel>
#include <QSlider>
#include "sliderproxy.h"
//#include "synth1tab.h"
#include "fpga.h"
#include <stdint.h>
#include <QTextEdit>
#include <QComboBox>

#include <QWidget>
#include "keyboard/widgetKeyBoard.h"
#include "examplemyfocus.h"

#define button_width 90
#define button_height 35

class fileTab : public QWidget
{
    Q_OBJECT

public:
    explicit fileTab(QWidget *parent = 0);
    FPGAFS *fpga;
    ~fileTab();
//    synth1Tab* synthTab;
    QPushButton *closebutton;
    QPushButton *fileopenbutton;
    QPushButton *keyboardopenbutton;
    QPushButton *keyboardclosebutton;

    widgetKeyBoard  *myKeyboard;

    //    QPushButton *synthtolcdbutton;
    QTextEdit *display;
//    QLineEdit *lineed;

signals:
    void quit_touched(void);
    void key_return_touched(void);
//    void synthread_touched(void);

public slots:
    void on_closebutton_pressed();
     void on_keyboardopenbutton_pressed();
     void on_keyboardclosebutton_pressed();
//    void on_synthtolcdbutton_pressed();
    void open_file_dialog();
//    void saveSyxFile(QString filename);

private:
};

#endif // FILETAB_H
