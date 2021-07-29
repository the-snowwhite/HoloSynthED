#include "mainwindow.h"
#include "ui_mainwindow.h"
#include "filetab.h"
#include "synth1tab.h"
#include <QAbstractButton>
#include <QObject>
#include <qwt_plot.h>
#include <qwt_plot_curve.h>
#include <qwt_plot_grid.h>
#include <qwt_symbol.h>
#include <qwt_legend.h>
#include <QFile>
#include <QMessageBox>
#include <QFileDialog>
#include <QLabel>
#include<QScrollBar>
#include <QTouchEvent>

#define SYX_FILE_DIR "/home/holosynth/prg/syx/"
#define NUM_OSC 8

MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent)
//    ui(new Ui::MainWindow)
{
//    ui->setupUi(this);
//    this->setFixedSize(1280,800);// fix windows size
    this->setFixedSize(1366,768);// fix windows size
    mytabWidget = new QTabWidget(this);
    ftab1 = new fileTab();
    stab1 = new synth1Tab();

    mytabWidget->addTab(ftab1, tr("File Actions"));
    mytabWidget->addTab(stab1, tr("Synth1"));
    mytabWidget->setFixedSize(1350,768);
    mytabWidget->setGeometry(0,0,0,0);
    QObject::connect( ftab1 , SIGNAL(quit_touched()) ,this ,SLOT(close()));
    QObject::connect(stab1,SIGNAL(keyboard_view()),ftab1,SLOT(on_keyboardopenbutton_pressed()));
    QObject::connect(stab1,SIGNAL(keyboard_hide()),ftab1,SLOT(on_keyboardclosebutton_pressed()));
    QObject::connect(ftab1,SIGNAL(key_return_touched()),stab1,SLOT(save_preset_to_file2()));

    mytabWidget->setCurrentIndex(1);

    mytabWidget->show();
}

fileTab::fileTab(QWidget *parent)
    : QWidget(parent)
{
    fpga = new FPGAFS;
    closebutton = new QPushButton("Quit",this);
    fileopenbutton = new QPushButton("Open",this);
    keyboardopenbutton = new QPushButton("key open",this);
    keyboardclosebutton = new QPushButton("key close",this);
    closebutton->setGeometry(QRect(QPoint(10,10),QSize(button_width,button_height)));
    fileopenbutton->setGeometry(QRect(QPoint(10 +(2 * button_width), 10),QSize(button_width, button_height)));
    keyboardopenbutton->setGeometry(QRect(QPoint(10 +(5 * button_width), 10),QSize(button_width, button_height)));
    keyboardclosebutton->setGeometry(QRect(QPoint(10 +(7 * button_width), 10),QSize(button_width, button_height)));
    QObject::connect(closebutton, SIGNAL(pressed()) , this , SLOT(on_closebutton_pressed()));
    QObject::connect(fileopenbutton,SIGNAL(pressed()),this,SLOT(open_file_dialog()));
    QObject::connect(keyboardopenbutton,SIGNAL(pressed()),this,SLOT(on_keyboardopenbutton_pressed()));
    QObject::connect(keyboardclosebutton,SIGNAL(pressed()),this,SLOT(on_keyboardclosebutton_pressed()));
    display = new QTextEdit(this);
    display->setGeometry(QRect(QPoint(10, 100),QSize(400, 400)));

    this->myKeyboard = new widgetKeyBoard(false);
    this->myKeyboard->setZoomFacility(true);
    this->myKeyboard->enableSwitchingEcho(false); // enable possibility to change echo through keyboard
    this->myKeyboard->createKeyboard(); // only create keyboard
    QObject::connect(myKeyboard,SIGNAL(return_touched()),this,SIGNAL(key_return_touched()));
    //    ui->verticalLayout->addWidget(new QLabel(tr("Focus that below without virtual keyboard TAB:")));
//    ui->verticalLayout->addWidget(new exampleMyFocus(this->myKeyboard)); // example how-to voluntary focus (hand-focus or mouse-focus)
//    ui->verticalLayout->addWidget(new exampleMyFocus(this->myKeyboard)); // example how-to voluntary focus (hand-focus or mouse-focus)
}
fileTab::~fileTab()
{
    this->myKeyboard->hide(true);
    delete (this->myKeyboard);
}
void fileTab::on_closebutton_pressed()
{
    emit quit_touched();
}

void fileTab::on_keyboardopenbutton_pressed()
{
    qDebug("opening keyboard");
    this->myKeyboard->show(this);   // once created keyboard object, use this method to switch between windows
    this->myKeyboard->move(this->x(), this->y() + this->myKeyboard->height()+300); // to move keyboard
}

void fileTab::on_keyboardclosebutton_pressed()
{
   qDebug("hiding keyboard");
    myKeyboard->hide(true);
}

void fileTab::open_file_dialog()
{
    QFileDialog *fdiag = new QFileDialog(this);
    fdiag->setStyleSheet("QPushButton{min-height: 80px; min-width: 300px;}");

    QString filename = fdiag->getOpenFileName( this, tr("Read  syx Patch File"), SYX_FILE_DIR , tr("Document files (*.syx );;All files (*.*)"), 0, QFileDialog::DontUseNativeDialog );
//    readSyxFile(filename);
}
/*
void fileTab::saveSyxFile(QString filename)
{
//    synth1Tab* synthTab = new synth1Tab();
    display->append(filename);
    QFile fileB(filename);
    if (!fileB.open(QIODevice::WriteOnly))
    {
    QMessageBox::information(NULL,"show","Failed to open file");
    return;
    }
}
*/
synth1Tab::synth1Tab(QWidget *parent)
    : QWidget(parent)
{
    unsigned int i,j;
    fpga = new FPGAFS;
//    fileTab* ftab1 = new fileTab();
    // Make main value slider
    QPalette *p_slider = new QPalette;
    p_slider->setColor(QPalette::Background,Qt::green);
    main_slider = new QSlider(Qt::Vertical,this);
    main_slider->setGeometry(QRect(QPoint(1182,322),QSize(60,300)));
    aSliderProxy = new SliderProxy;
    main_slider->setStyle(aSliderProxy);
    main_slider->setMaximum(127);
    main_slider->setMinimum(0);
    main_slider->setPageStep(1);
    main_slider->setPalette(*p_slider);
    main_slider->show();
    main_lcd = new QLCDNumber(this);
    main_lcd->setGeometry(QRect(QPoint(1185,625),QSize(lcd_width+5,lcd_height)));
    main_lcd->setDigitCount(3);
    main_lcd->setSegmentStyle(QLCDNumber::Filled);
    main_lcd->show();
    QObject::connect(main_slider,SIGNAL(valueChanged(int)),main_lcd,SLOT(display(int)));

    // Make osc text labels
    oscLabels <<"osc "<<"  ct"<<"  ft"<<" vol"<<" m_o"<<"fb_o"<<"k_sc"<<" off"<<" pan"<<"b_ct"<<"b_ft"<<"m_in"<<"fb_in";
    for(i=0;i<13;i++)
    {
        osc_label[i] = new QLabel(oscLabels[i],this);
        osc_label[i]->setGeometry(QRect(QPoint((0+(lcd_width * i)),(0)),QSize(lcd_width,lcd_height)));
        osc_label[i]->show();
    }
    for(i=0;i<NUM_OSC;i++)
    {
        osc_num_label[i] = new QLabel(QString::number(i+1),this);
        osc_num_label[i]->setGeometry(QRect(QPoint(10,(20+(lcd_height*i))),QSize(lcd_width,lcd_height)));
        osc_num_label[i]->show();
    }

    // Make osc lcds + selectbuttons and value view regs
    QPalette *p_osc = new QPalette;
    p_osc->setColor(QPalette::WindowText,Qt::red);
    for(j=0;j<NUM_OSC;j++)
    {
        for(i = 0;i<12;i++){
            osc_lcd[i][j] = new QLCDNumber(this);
            osc_lcd[i][j]->setGeometry(QRect(QPoint((34+(lcd_width * i)),(28 + (lcd_height * j))),QSize(lcd_width,lcd_height)));
            osc_lcd[i][j]->setDigitCount(3);
            osc_lcd[i][j]->setSegmentStyle(QLCDNumber::Filled);
            osc_lcd[i][j]->setPalette(*p_osc);
            osc_button[i][j] = new QPushButton("" ,this);
            osc_button[i][j]->setGeometry(QRect(QPoint((34+(lcd_width * i)),(28+ (lcd_height * j))),QSize(lcd_width,lcd_height)));
            osc_button[i][j]->setFlat(true);
            QObject::connect(osc_button[i][j],SIGNAL(pressed()),this,SLOT(osc_button_pressed()));
        }
    }

    // Make matrix text labels
    matLabels <<" osc "<<"in 1"<<"in 2"<<"in 3"<<"in 4"<<"in 5"<<"in 6"<<"in 7"<<"in 8";
    for(z=0;z<2;z++)
    {
        x_offset = z * 360;
        xi = z * 8;
        for(i=0;i<9;i++)
        {
            mat_label[i+xi] = new QLabel(matLabels[i],this);
            mat_label[i+xi]->setGeometry(QRect(QPoint((x_offset + 522+(lcd_width * i)),(0)),QSize(lcd_width,(lcd_height))));
            mat_label[i+xi]->show();
        }
        xy = z * 8;
        for(i=0;i<NUM_OSC;i++)
        {
            mat_num_label[i+xy] = new QLabel(QString::number(i+1)+">",this);
            mat_num_label[i+xy]->setGeometry(QRect(QPoint(x_offset + 530,(30+(lcd_height*i))),QSize(lcd_width,lcd_height)));
            mat_num_label[i+xy]->show();
        }
        // Make mod and fb matrix lcds and buttons
        QPalette *p_mat = new QPalette;
        p_mat->setColor(QPalette::WindowText,Qt::blue);
        for(j=0;j<NUM_OSC;j++)
        {
            for(i = 0;i<NUM_OSC;i++){
                mat_lcd[i+xy][j] = new QLCDNumber(this);
                mat_lcd[i+xy][j]->setGeometry(QRect(QPoint((x_offset +550+(lcd_width * i)),(28 + (lcd_height * j))),QSize(lcd_width,lcd_height)));
                mat_lcd[i+xy][j]->setDigitCount(3);
                mat_lcd[i+xy][j]->setSegmentStyle(QLCDNumber::Filled);
                mat_lcd[i+xy][j]->setPalette(*p_mat);
                mat_button[i+xy][j] = new QPushButton("" ,this);
                mat_button[i+xy][j]->setGeometry(QRect(QPoint((x_offset +550+(lcd_width * i)),(28+ (lcd_height * j))),QSize(lcd_width,lcd_height)));
                mat_button[i+xy][j]->setFlat(true);
                QObject::connect(mat_button[i+xy][j],SIGNAL(pressed()),this,SLOT(mat_button_pressed()));
            }
        }
    }

    // Make Envelope text labels
    for(j=0;j<9;j++)
    {
        p_env[j] = new QPalette;
        switch (j) {
        case 0:
            x_offset = 0; y_offset = 0; z=0; o=0;
            p_env[j]->setColor(QPalette::WindowText,Qt::green);
            break;
        case 1:
            x_offset = 876; y_offset = 140; z=0; o=8;
            p_env[j]->setColor(QPalette::WindowText,Qt::black);
            break;
        case 2:
            x_offset = 220; y_offset = 0; z=1; o=0;
            p_env[j]->setColor(QPalette::WindowText,Qt::blue);
            break;
        case 3:
            x_offset = 440; y_offset = 0; z=2; o=0;
            p_env[j]->setColor(QPalette::WindowText,Qt::red);
            break;
        case 4:
            x_offset = 660; y_offset = 0; z=3; o=0;
            p_env[j]->setColor(QPalette::WindowText,Qt::magenta);
            break;
        case 5:
            x_offset = 0; y_offset = 200; z=4; o=0;
            p_env[j]->setColor(QPalette::WindowText,Qt::green);
            break;
        case 6:
            x_offset = 220; y_offset = 200; z=5; o=0;
            p_env[j]->setColor(QPalette::WindowText,Qt::blue);
            break;
        case 7:
            x_offset = 440; y_offset = 200; z=6; o=0;
            p_env[j]->setColor(QPalette::WindowText,Qt::red);
            break;
        case 8:
            x_offset = 660; y_offset = 200; z=7; o=0;
            p_env[j]->setColor(QPalette::WindowText,Qt::magenta);
            break;
        default:
            break;
        }
        envLabels <<" Rate "<<"Level";
        for(i=0;i<2;i++)
        {
            env_label[i][j] = new QLabel(envLabels[i],this);
            env_label[i][j]->setGeometry(QRect(QPoint(x_offset + 10,(y_offset + 445+(lcd_height*i))),QSize(lcd_width,lcd_height)));
            env_label[i][j]->show();
        }
        for(i=0;i<4;i++)
        {
            env_num_label[i][j] = new QLabel(QString::number(i+1),this);
            env_num_label[i][j]->setGeometry(QRect(QPoint((x_offset + 70+(lcd_width * i)),(y_offset + 420)),QSize(lcd_width,(lcd_height))));
            env_num_label[i][j]->show();
        }

        // Make Envelope lcd's and select buttons
        for(xi=0;xi<2;xi++)
        {
            for(i = 0;i<4;i++){
                env_lcd[(o+i+(xi*4))][z] = new QLCDNumber(this);
                env_lcd[(o+i+(xi*4))][z]->setGeometry(QRect(QPoint((x_offset + 50+(lcd_width * i)),(y_offset + 445 + (lcd_height * xi))),QSize(lcd_width,lcd_height)));
                env_lcd[(o+i+(xi*4))][z]->setDigitCount(3);
                env_lcd[(o+i+(xi*4))][z]->setSegmentStyle(QLCDNumber::Filled);
                env_lcd[(o+i+(xi*4))][z]->setPalette(*p_env[j]);
                env_button[(o+i+(xi*4))][z] = new QPushButton("" ,this);
                env_button[(o+i+(xi*4))][z]->setGeometry(QRect(QPoint((x_offset + 50+(lcd_width * i)),(y_offset + 445+ (lcd_height * xi))),QSize(lcd_width,lcd_height)));
                env_button[(o+i+(xi*4))][z]->setFlat(true);
                QObject::connect(env_button[(o+i+(xi*4))][z],SIGNAL(pressed()),this,SLOT(env_button_pressed()));
            }
        }
    }

    // Make Envelope qwt display
    for(i=0;i<9;i++)
    {
        qwtPlotenv[i] = new QwtPlot(this);
        curve[i] = new QwtPlotCurve();
        curve[i]->setRenderHint( QwtPlotItem::RenderAntialiased, true );
        symbol[i] = new QwtSymbol( QwtSymbol::Ellipse,
                                   QBrush( Qt::yellow ), QPen( Qt::red, 2 ), QSize( 8, 8 ) );
        curve[i]->setSymbol( symbol[i] );
        points[i] << QPointF(0, 0 ) << QPointF( 0, 0 ) << QPointF( 0, 0 )
                  << QPointF( 0 , 127) << QPointF( 0 , 0 );
        curve[i]->setSamples( points[i] );
        curve[i]->attach( qwtPlotenv[i] );
        qwtPlotenv[i]->setAxisScale(QwtPlot::yLeft,0,127,0);
        qwtPlotenv[i]->setAxisScale(QwtPlot::xBottom ,0,508,0);
        qwtPlotenv[i]->enableAxis(QwtPlot::xBottom,false);
        qwtPlotenv[i]->enableAxis(QwtPlot::yLeft,false);
        qwtPlotenv[i]->show();
    }
    curve[0]->setPen( Qt::green, 4 );
    curve[1]->setPen( Qt::black, 4 );
    curve[2]->setPen( Qt::blue, 4 );
    curve[3]->setPen( Qt::red, 4 );
    curve[4]->setPen( Qt::magenta, 4 );
    curve[5]->setPen( Qt::green, 4 );
    curve[6]->setPen( Qt::blue, 4 );
    curve[7]->setPen( Qt::red, 4 );
    curve[8]->setPen( Qt::magenta, 4 );
    qwtPlotenv[0]->setGeometry(QRect(QPoint(10,330),QSize(200,100)));
    qwtPlotenv[1]->setGeometry(QRect(QPoint(890,480),QSize(200,100)));
    qwtPlotenv[2]->setGeometry(QRect(QPoint(230,330),QSize(200,100)));
    qwtPlotenv[3]->setGeometry(QRect(QPoint(450,330),QSize(200,100)));
    qwtPlotenv[4]->setGeometry(QRect(QPoint(670,330),QSize(200,100)));
    qwtPlotenv[5]->setGeometry(QRect(QPoint(10,520),QSize(200,100)));
    qwtPlotenv[6]->setGeometry(QRect(QPoint(230,520),QSize(200,100)));
    qwtPlotenv[7]->setGeometry(QRect(QPoint(450,520),QSize(200,100)));
    qwtPlotenv[8]->setGeometry(QRect(QPoint(670,520),QSize(200,100)));

    // Make com text labels
    comLabels <<"  pb \nrange"<<"main \n  vol"<<"midi \n  ch "<<" vel\nscale"<<" osc  \nindex" <<" dev \n  id " << " oc\ntave";
    for(i=0;i<7;i++)
    {
        com_label[i] = new QLabel(comLabels[i],this);
        com_label[i]->setGeometry(QRect(QPoint((892+(lcd_width * i)),(380)),QSize(lcd_width,(lcd_height+15))));
        com_label[i]->show();
    }
    // Make com lcds + selectbuttons and value view regs
    p_com = new QPalette;
    p_com->setColor(QPalette::WindowText,Qt::black);
//    p_com->setColor(QPalette::Window ,Qt::darkGray);
    for(i = 0;i<7;i++){
        com_lcd[i] = new QLCDNumber(this);
        com_lcd[i]->setGeometry(QRect(QPoint((890+(lcd_width * i)),422 ),QSize(lcd_width,lcd_height)));
        com_lcd[i]->setDigitCount(3);
        com_lcd[i]->setSegmentStyle(QLCDNumber::Filled);
        com_lcd[i]->setPalette(*p_com);
        com_button[i] = new QPushButton("" ,this);
        com_button[i]->setGeometry(QRect(QPoint((890+(lcd_width * i)),422),QSize(lcd_width,lcd_height)));
        com_button[i]->setFlat(true);
        QObject::connect(com_button[i],SIGNAL(pressed()),this,SLOT(com_button_pressed()));
    }

    midiinternCheckBox = new QCheckBox("Hw Midi In",this);
    midiinternCheckBox->setGeometry(QRect(QPoint(970,450),QSize(120,35)));
    QObject::connect(midiinternCheckBox,SIGNAL(pressed()),this,SLOT(midi_intern_pressed()));
    midiinternCheckBox->show();

    QObject::connect(main_slider,SIGNAL(valueChanged(int)),this,SLOT(main_slider_val_change(int)));

    synthtolcdbutton = new QPushButton("Read",this);
    synthtolcdbutton->setGeometry(QRect(QPoint(1170 , 660),QSize(button_width, button_height)));
    QObject::connect(synthtolcdbutton,SIGNAL(pressed()),this,SLOT(synthtolcd()));

    filenamelineedit = new QLineEdit(this);
    filenamelineedit->setGeometry(QRect(QPoint(895, 325),QSize(280, 50)));
    QFont font2("Times",20);
    filenamelineedit->setFont(font2);
    filenamelineedit->setMaxLength(16);
    QObject::connect(filenamelineedit,SIGNAL(textChanged(QString)),this,SLOT(filenametext_changed(QString)));

    // read valus into Gui
    QByteArray gui_only = qgetenv("GUI_ONLY");
    if( gui_only.isEmpty())
    {
        synthtolcd();
    }
    fileloadbox = new QComboBox(this);
    fileloadbox->setGeometry(QRect(QPoint(885,275),QSize(350,35)));
    QFont font1("Times",16);
    fileloadbox->setFont(font1);
    populate_fileloadbox();
    QObject::connect(fileloadbox,SIGNAL(activated(QString)),this,SLOT(on_fileloadbox_activated(QString)));

    fileloadbox->setStyleSheet(" QComboBox { border: 1px solid gray;"
                               "border-radius: 3px; padding: 1px 48px 1px 3px; min-width: 6em; }"
                               "QScrollBar:vertical {border: 1px solid black; background:green; width:60px; margin: 0px 0px 0px 0px; }"
                               );

    for(i=0;i<10;i++) {
        presetbutton[i] = new QPushButton("Preset"+QString::number(i+1),this);
        presetbutton[i]->setGeometry(QRect(QPoint((10 + (i *(button_width - 2) )) , 275),QSize((button_width-10), button_height)));
        QObject::connect(presetbutton[i],SIGNAL(pressed()),this,SLOT(preset_pressed()));
        QObject::connect(presetbutton[i],SIGNAL(released()),this,SLOT(preset_released()));
    }
    presetlistenCheckBox = new QCheckBox("Preset Listen",this);
    presetlistenCheckBox->setGeometry(QRect(QPoint(885,665),QSize(120,35)));
    presetlistenCheckBox->show();
    keyboard2openbutton = new QPushButton("key open",this);
    keyboard2openbutton->setGeometry(QRect(QPoint(985, 665),QSize(button_width, button_height)));
    QObject::connect(keyboard2openbutton,SIGNAL(pressed()),this,SLOT(on_keyboard2openbutton_pressed()));
    keyboard2closebutton = new QPushButton("key end",this);
    keyboard2closebutton->setGeometry(QRect(QPoint(1075, 665),QSize(button_width, button_height)));
    QObject::connect(keyboard2closebutton,SIGNAL(pressed()),this,SLOT(on_keyboard2closebutton_pressed()));

} // synth1Tab::synth1Tab()  end

void synth1Tab::synthtolcd()
{
    u_int8_t regvalue;
    unsigned int Address;
    qDebug("synth2lcd start");
    //        for(Address = 0x000;Address<0x040;Address++)
    for(Address = 0x000;Address<0x018;Address++) { // env 1, main vol env, env  2
        regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
    for(Address = 0x020;Address<0x028;Address++) { // env 3
        regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
    for(Address = 0x030;Address<0x038;Address++) { // env  4
        regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
    for(Address = 0x040;Address<0x048;Address++) { // env  5
        regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
    for(Address = 0x050;Address<0x058;Address++) { // env  6
        regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
    for(Address = 0x060;Address<0x068;Address++) { // env  7
        regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
    for(Address = 0x070;Address<0x078;Address++) { // env  8
        regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
    for(Address = 0x080;Address<0x08c;Address++) { // osc 1
        regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
    for(Address = 0x090;Address<0x09c;Address++) { // osc 2
        regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
    for(Address = 0x0a0;Address<0x0ac;Address++) { // osc 3
        regvalue = fpga->SynthregGet(Address);                   setLCD(Address,regvalue);  }
    for(Address = 0x0b0;Address<0x0bc;Address++) { // osc 4
        regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
    for(Address = 0x0c0;Address<0x0cc;Address++) { // osc 5
        regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
    for(Address = 0x0d0;Address<0x0dc;Address++) { // osc 6
        regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
    for(Address = 0x0e0;Address<0x0ec;Address++) { // osc 7
        regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
    for(Address = 0x0f0;Address<0x0fc;Address++) { // osc 8
        regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
     for(Address = 0x100 ;Address<0x180;Address++) { // mod + fb matrix
         regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
     for(Address =0x280;Address<0x282;Address++) { // common
        regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
     for(Address =0x290;Address<0x2A0;Address++) { // common patch name
         regvalue = fpga->SynthregGet(Address);                  setLCD(Address,regvalue);  }
     qDebug("synth2lcd end");
     filenamelineedit->setText(patch_name);                    // common patch name
//     filenamelineedit->setText("hello");                    // common patch name
    qDebug("Set filenamelineedit text= %s",qPrintable( patch_name));
}

void synth1Tab::setEnvPlot(int envNr)
{
    int x[4];
    switch (envNr) {
    case 1:// env 1
        x[0] = env_lcd[0][0]->value();
        x[1] = env_lcd[1][0]->value();
        x[2] = env_lcd[2][0]->value();
        x[3] = env_lcd[3][0]->value();
        points[0].clear();
        points[0] << QPointF( 0, 0 ) << QPointF( x[0], env_lcd[4][0]->value() ) << QPointF( x[0] + x[1], env_lcd[5][0]->value() )
            << QPointF( x[0] + x[1] + x[2], env_lcd[6][0]->value() ) << QPointF( x[0] + x[1] + x[2] + x[3],env_lcd[7][0]->value() );
        curve[0]->setSamples( points[0] );
        qwtPlotenv[0]->replot();
        break;
    case 2: // Main vol env
        x[0] = env_lcd[8][0]->value();
        x[1] = env_lcd[9][0]->value();
        x[2] = env_lcd[10][0]->value();
        x[3] = env_lcd[11][0]->value();
        points[1].clear();
        points[1] << QPointF( 0, 0 ) << QPointF( x[0], env_lcd[12][0]->value() ) << QPointF( x[0] + x[1], env_lcd[13][0]->value() )
            << QPointF( x[0] + x[1] + x[2], env_lcd[14][0]->value() ) << QPointF( x[0] + x[1] + x[2] + x[3],env_lcd[15][0]->value() );
        curve[1]->setSamples( points[1] );
        qwtPlotenv[1]->replot();
        break;
    case 3:// env 2
        x[0] = env_lcd[0][1]->value();
        x[1] = env_lcd[1][1]->value();
        x[2] = env_lcd[2][1]->value();
        x[3] = env_lcd[3][1]->value();
        points[2].clear();
        points[2] << QPointF( 0, 0 ) << QPointF( x[0], env_lcd[4][1]->value() ) << QPointF( x[0] + x[1], env_lcd[5][1]->value() )
            << QPointF( x[0] + x[1] + x[2], env_lcd[6][1]->value() ) << QPointF( x[0] + x[1] + x[2] + x[3],env_lcd[7][1]->value() );
        curve[2]->setSamples( points[2] );
        qwtPlotenv[2]->replot();
        break;
    case 4:// env 3
        x[0] = env_lcd[0][2]->value();
        x[1] = env_lcd[1][2]->value();
        x[2] = env_lcd[2][2]->value();
        x[3] = env_lcd[3][2]->value();
        points[3].clear();
        points[3] << QPointF( 0, 0 ) << QPointF( x[0], env_lcd[4][2]->value() ) << QPointF( x[0] + x[1], env_lcd[5][2]->value() )
            << QPointF( x[0] + x[1] + x[2], env_lcd[6][2]->value() ) << QPointF( x[0] + x[1] + x[2] + x[3],env_lcd[7][2]->value() );
        curve[3]->setSamples( points[3] );
        qwtPlotenv[3]->replot();
        break;
    case 5:// env 4
        x[0] = env_lcd[0][3]->value();
        x[1] = env_lcd[1][3]->value();
        x[2] = env_lcd[2][3]->value();
        x[3] = env_lcd[3][3]->value();
        points[4].clear();
        points[4] << QPointF( 0, 0 ) << QPointF( x[0], env_lcd[4][3]->value() ) << QPointF( x[0] + x[1], env_lcd[5][3]->value() )
            << QPointF( x[0] + x[1] + x[2], env_lcd[6][3]->value() ) << QPointF( x[0] + x[1] + x[2] + x[3],env_lcd[7][3]->value() );
        curve[4]->setSamples( points[4] );
        qwtPlotenv[4]->replot();
        break;
    case 6:// env 5
        x[0] = env_lcd[0][4]->value();
        x[1] = env_lcd[1][4]->value();
        x[2] = env_lcd[2][4]->value();
        x[3] = env_lcd[3][4]->value();
        points[5].clear();
        points[5] << QPointF( 0, 0 ) << QPointF( x[0], env_lcd[4][4]->value() ) << QPointF( x[0] + x[1], env_lcd[5][4]->value() )
            << QPointF( x[0] + x[1] + x[2], env_lcd[6][4]->value() ) << QPointF( x[0] + x[1] + x[2] + x[3],env_lcd[7][4]->value() );
        curve[5]->setSamples( points[5] );
        qwtPlotenv[5]->replot();
        break;
    case 7:// env 6
        x[0] = env_lcd[0][5]->value();
        x[1] = env_lcd[1][5]->value();
        x[2] = env_lcd[2][5]->value();
        x[3] = env_lcd[3][5]->value();
        points[6].clear();
        points[6] << QPointF( 0, 0 ) << QPointF( x[0], env_lcd[4][5]->value() ) << QPointF( x[0] + x[1], env_lcd[5][5]->value() )
            << QPointF( x[0] + x[1] + x[2], env_lcd[6][5]->value() ) << QPointF( x[0] + x[1] + x[2] + x[3],env_lcd[7][5]->value() );
        curve[6]->setSamples( points[6] );
        qwtPlotenv[6]->replot();
        break;
    case 8:// env 7
        x[0] = env_lcd[0][6]->value();
        x[1] = env_lcd[1][6]->value();
        x[2] = env_lcd[2][6]->value();
        x[3] = env_lcd[3][6]->value();
        points[7].clear();
        points[7] << QPointF( 0, 0 ) << QPointF( x[0], env_lcd[4][6]->value() ) << QPointF( x[0] + x[1], env_lcd[5][6]->value() )
            << QPointF( x[0] + x[1] + x[2], env_lcd[6][6]->value() ) << QPointF( x[0] + x[1] + x[2] + x[3],env_lcd[7][6]->value() );
        curve[7]->setSamples( points[7] );
        qwtPlotenv[7]->replot();
        break;
    case 9:// env 8
        x[0] = env_lcd[0][7]->value();
        x[1] = env_lcd[1][7]->value();
        x[2] = env_lcd[2][7]->value();
        x[3] = env_lcd[3][7]->value();
        points[8].clear();
        points[8] << QPointF( 0, 0 ) << QPointF( x[0], env_lcd[4][7]->value() ) << QPointF( x[0] + x[1], env_lcd[5][7]->value() )
            << QPointF( x[0] + x[1] + x[2], env_lcd[6][7]->value() ) << QPointF( x[0] + x[1] + x[2] + x[3],env_lcd[7][7]->value() );
        curve[8]->setSamples( points[8] );
        qwtPlotenv[8]->replot();
        break;
   default:
        break;
    }
}

void synth1Tab::env_button_pressed(void)
{
    unsigned int reg_num, i,j;
    for(j=0;j<NUM_OSC;j++)
    {
        if(j==0) reg_num =16;
        else reg_num = 8;
        for(i=0;i<reg_num;i++)
        {
            if(env_button[i][j]->QAbstractButton::isDown())
            {
                Addressreg_x = i; Addressreg_y = j;
                val = env_lcd[i][j]->value();
                main_slider->setRange(0,127);
                main_slider->setValue(val);
            }
       }
    }
}

void synth1Tab::osc_button_pressed(void)
{
    unsigned int i,j;
    for(j=0;j<NUM_OSC;j++)
    {
        for(i=0;i<12;i++)
        {
            if(osc_button[i][j]->QAbstractButton::isDown())
            {
                qDebug( "pressed i = %d j = %d",i,j);
                Addressreg_x = i; Addressreg_y = j+8;
                val = osc_lcd[i][j]->value();
                if((i < 2) || (i >= 7 && i <= 9) ) {
                    main_slider->setRange(-64,63);
                    main_slider->setValue(val);
                }
                else {
                    main_slider->setRange(0,127);
                    main_slider->setValue(val);
                }
            }
        }
    }
}

void synth1Tab::mat_button_pressed(void)
{
    unsigned int i,j;

    for(j=0;j<NUM_OSC;j++)
    {
        for(i=0;i<16;i++)
        {
            if(mat_button[i][j]->QAbstractButton::isDown())
            {
                Addressreg_x = i; Addressreg_y = j+(NUM_OSC * 2);
                val = mat_lcd[i][j]->value();
                main_slider->setRange(0,127);
                main_slider->setValue(val);
            }
        }
    }
}

void synth1Tab::com_button_pressed(void)
{
    unsigned int i;
    for(i=0;i<7;i++)
    {
        if(com_button[i]->QAbstractButton::isDown())
        {
            Addressreg_x = i; Addressreg_y = (NUM_OSC * 5);
            if(i == 2) {
                main_slider->setRange(0,15);
                val = com_lcd[i]->value();
            } else {
                main_slider->setRange(0,127);
                val = com_lcd[i]->value();
            }
            main_slider->setValue(val);
        }
    }
}

void synth1Tab::midi_intern_pressed(void){
    unsigned int regaddress;
    regaddress = ((NUM_OSC * 5) << 4) + 2;
    if(midiinternCheckBox->isChecked()){
        val = ((int) com_lcd[2]->value()) | 0x10;
    } else {
        val = ((int) com_lcd[2]->value()) & 0xf;
    }
    fpga->SynthregSet(regaddress,val);
}

void synth1Tab::main_slider_val_change(int value)
{
    unsigned int regaddress, reg_x;
    regaddress = (Addressreg_y << 4) + Addressreg_x;
    reg_x = regaddress & 0xf;
    qDebug("slider change regaddress = 0x%x  Set to value --> %d",regaddress,value);
    if((reg_x < 2) || (reg_x >= 7 && reg_x <= 9)) {
        fpga->SynthregSet(regaddress,value+64);
        setLCD(regaddress, value+64);
    }
    else {
        fpga->SynthregSet(regaddress,value);
        setLCD(regaddress, value);
    }
}
void synth1Tab::setLCD(unsigned int RegAddress, u_int8_t newValue)
{
   unsigned  int reg_y,reg_x;
    reg_x = RegAddress & 0xf;
    qDebug("setLCD RegAddress = 0x%x value= %d",RegAddress,newValue);
    if(RegAddress < 0x080)
    {
         reg_y = (RegAddress & 0xf0) >> 4;
         env_lcd[reg_x][reg_y]->display(newValue);
        switch (reg_y) {
        case 0:     if(reg_x<8) setEnvPlot(1); else setEnvPlot(2); break;
        case 1:     setEnvPlot(3); break;
        case 2:     setEnvPlot(4); break;
        case 3:     setEnvPlot(5); break;
        case 4:     setEnvPlot(6); break;
        case 5:     setEnvPlot(7); break;
        case 6:     setEnvPlot(8); break;
        case 7:     setEnvPlot(9); break;
        default:    break;
        }
    }
    else if(RegAddress >= 0x080 && (RegAddress < 0x100))
    {
        reg_y =( (RegAddress & 0xff0 ) >> 4) - 8;
        if((reg_x < 2) || (reg_x >= 7 && reg_x <= 9)) {osc_lcd[reg_x][reg_y]->display(newValue-64);}
        else osc_lcd[reg_x][reg_y]->display(newValue);
    }
    else if(RegAddress >= 0x100 && RegAddress < 0x180)
    {
       reg_y = ( (RegAddress & 0xff0) >> 4) - 0x10;
       mat_lcd[reg_x][reg_y]->display(newValue);
    }
    else if(RegAddress >= 0x280 && RegAddress < 0x287)
    {
        com_lcd[reg_x]->display(newValue);
        if(RegAddress == 0x282) {
            if((newValue & 0x10) == 0){
                midiinternCheckBox->setChecked(true);
            }
        }
    }
    else if(RegAddress >=0x290 && RegAddress < 0x2A0)
    {
        if(RegAddress == 0x290) patch_name.clear();
        patch_name.append((char) newValue);
    }
//    qDebug( "patchname is: " + patch_name);
    filenamelineedit->clear();
    filenamelineedit->setText(patch_name);
}

void synth1Tab::populate_fileloadbox()
{
    QStringList nameFilter("*.syx");
    QDir directory(SYX_FILE_DIR);
    QStringList syxFilesAndDirectories = directory.entryList(nameFilter);
    fileloadbox->clear();
    fileloadbox->addItems(syxFilesAndDirectories);
}

void synth1Tab::on_fileloadbox_activated(const QString &file)
{
    fileTab *ftab1 = new fileTab();
    ftab1->display->append(file);
    patch_name.clear();
    readSyxFile(SYX_FILE_DIR + file);
}

void synth1Tab::preset_pressed()
{
    unsigned int r, size;
    for(r=0;r<10;r++)
    {
        if(presetbutton[r]->QAbstractButton::isDown())
        {
            active_preset = r;
//            QMessageBox msgBox;//,msgBox2;
//            QMessageBox *msgBox2 = new QMessageBox;
            if(PresetBuffer[r].isEmpty())
            {
                preset_state = 1;// preset_was empty
                size = save_preset_to_array(r);
                p_size = size;
//                qDebug("size = %d",size);
                presetbutton[r]->setStyleSheet("background-color:cyan");
            }
            else  if(presetlistenCheckBox->isChecked()){
                size = load_preset_from_array(r);
                presetbutton[r]->setStyleSheet("background-color:green");
                p_size = size;
                preset_state = 0;  // no button released processing
            }
            else {
                preset_state = 2; // preset is full
            }
        }
    }
}

void synth1Tab::preset_released()
{
    unsigned int size ;
    QMessageBox *msgBox = new QMessageBox;
    QMessageBox *msgBox2 = new QMessageBox;
    if(preset_state == 1)
    {
        msgBox2->setText("<font size=12 > Preset "+ QString::number(active_preset + 1)+ " stored <br> size is " + QString::number(p_size) + " bytes  </font> ");
        msgBox2->setStyleSheet("background-color:cyan");
        msgBox2->exec();
    }
    else if (preset_state == 2)
    {
        msgBox->setText("<font size=12 > Preset " + QString::number(active_preset+1) + " is in use <br> do you want to overwrite, recall or save ?</font>");
        overwriteButton = msgBox->addButton(tr("Overwrite"), QMessageBox::ActionRole);
        overwriteButton->setStyleSheet("background-color:cyan");
        overwriteButton->setAttribute(Qt::WA_AcceptTouchEvents);
        recallButton = msgBox->addButton(tr("Recall"), QMessageBox::ActionRole);
        saveButton = msgBox->addButton(tr("Save"), QMessageBox::ActionRole);
        cancelButton = msgBox->addButton(tr("Cancel"), QMessageBox::ActionRole);
        int ret = msgBox->exec();
        if (msgBox->clickedButton() == overwriteButton){
            PresetBuffer[active_preset].clear();
            size = save_preset_to_array(active_preset);
           msgBox2->setText("<font size=12 >Preset "+ QString::number(active_preset + 1)+ " stored<br> size is " + QString::number(size) + " bytes </font> ");
           msgBox2->exec();
        }
        else if (msgBox->clickedButton() == recallButton){
            size = load_preset_from_array(active_preset);
//            presetbutton[active_preset]->setStyleSheet("background-color:green");
            msgBox2->setText("<font size=12 >Preset "+ QString::number(active_preset + 1)+ " loaded<br> size is " + QString::number(size) + " bytes </font>");
            msgBox2->exec();
        }
        else if (msgBox->clickedButton() == saveButton){
            size = save_preset_to_file1(active_preset);
            size = PresetBuffer[active_preset].size() + 4;
        }
        else if (msgBox->clickedButton() == cancelButton){
           msgBox2->setText("<font size=12 > Action Cancled </font>");
           msgBox2->exec();
        }
        qDebug("msxbox ret = %d",ret);

    }
}

void synth1Tab::overwritebutton_pressed()
{

}

unsigned int synth1Tab::save_preset_to_array(unsigned int arraynum)
{
    u_int8_t val;
    unsigned int i,size;
    for(i=0;i<672;i++) {
//        if(i<647)
            val = fpga->SynthregGet(i);
//        else val = 32;
        PresetBuffer[arraynum].append((char) val);
        qDebug("PresetBuffer[%d] Address = 0x%x value= %d",arraynum, i, val);
    }
    size = PresetBuffer[arraynum].size();
    return(size);
}

unsigned int synth1Tab::load_preset_from_array(unsigned int arraynum)
{
    u_int8_t val;
    unsigned int i,j;
    unsigned int PreserBufferIndex = 0;

    for(j=0;j<NUM_OSC;j++) // Envs
    {
        for(i=0;i<16;i++)
        {
            val = PresetBuffer[arraynum].at(PreserBufferIndex);
            fpga->SynthregSet(PreserBufferIndex,val);
            if(j==0 || i<8) {  setLCD(PreserBufferIndex,val); }
            PreserBufferIndex++;
        }
    }

    for(j=0;j<NUM_OSC;j++) // Oscs
    {
        for(i=0;i<16;i++)
        {
            val = PresetBuffer[arraynum].at(PreserBufferIndex);
            fpga->SynthregSet(PreserBufferIndex,val);
            if(i<12) setLCD(PreserBufferIndex,val);
            PreserBufferIndex++;
        }
    }
    for(j=0;j<NUM_OSC;j++) // Mat 1
    {
        for(i=0;i<16;i++)
        {
            val = PresetBuffer[arraynum].at(PreserBufferIndex);
            fpga->SynthregSet(PreserBufferIndex,val);
            setLCD(PreserBufferIndex,val);
            PreserBufferIndex++;
        }
    }
    for(j=0;j<NUM_OSC;j++) // Mat 2
    {
        for(i=0;i<16;i++)
        {
            PreserBufferIndex++;
        }
    }
    for(j=0;j<NUM_OSC;j++) // Spare
    {
        for(i=0;i<16;i++)
        {
            PreserBufferIndex++;
        }
    }
    for(j=0;j<2;j++) // Com
    {
        for(i=0;i<16;i++)
        {
            val = PresetBuffer[arraynum].at(PreserBufferIndex);
            fpga->SynthregSet(PreserBufferIndex,val);
            if(j== 0 && i<7)   setLCD(PreserBufferIndex,val);
            else if(j==1) setLCD(PreserBufferIndex,val);
            PreserBufferIndex++;
        }
    }
    return(PresetBuffer[arraynum].size());
}

void synth1Tab::on_keyboard2openbutton_pressed()
{
    emit keyboard_view();
}

void synth1Tab::on_keyboard2closebutton_pressed()
{
    emit keyboard_hide();
}

unsigned int synth1Tab::save_preset_to_file1(unsigned int arraynum)
{
    cur_save_index = arraynum;
    emit keyboard_view();
    return(arraynum);
}

unsigned int synth1Tab::save_preset_to_file2()
{
    QString filename =  filenamelineedit->text() + ".syx";
    QStringList nameFilter("*.syx");
    QDir directory(SYX_FILE_DIR);//SYX_FILE_DIR
    QStringList syxFilesAndDirectories = directory.entryList(nameFilter);
    emit keyboard_hide();
    if(syxFilesAndDirectories.contains(filename)) {
        QMessageBox *msgBox = new QMessageBox;
        QPushButton *overwriteButton = msgBox->addButton(tr("Overwrite"), QMessageBox::ActionRole);
        overwriteButton->setStyleSheet("background-color:cyan");
        QPushButton *renameButton = msgBox->addButton(tr("Rename"), QMessageBox::ActionRole);
        msgBox->setText("<font size=12 > Filename:  " + filename + " allready exists  <br> do you want to overwrite or rename ?</font>");
        msgBox->exec();
        if (msgBox->clickedButton() == overwriteButton){
            write_syx_file(filename);
        }
        else if (msgBox->clickedButton() == renameButton){
            emit keyboard_view();
            return(0);
        }
    }
    else {
        write_syx_file(filename);
    }

    return(2);
}

void synth1Tab::readSyxFile(QString filename)
{
    unsigned int filetype = 0;
    unsigned int Address;
    unsigned int FileBufferIndex;
    u_int8_t regvalue;

//    synth1Tab* synthTab = MainWindow::ftab1;  //new synth1Tab();
//    display->append(filename);
    QFile fileB(filename);
    if (!fileB.open(QIODevice::ReadOnly))
    {
        QMessageBox::information(NULL,"show","<font size=12 > Failed to read</font>");
        return;
    }
    Buffer=fileB.readAll();
    fileB.close();
    // read file into synth regs and ui
    // Env 1, main vol , env 2
    if(Buffer.size() == 228 ) filetype = 1;
    else if(Buffer.size() == 676 ) filetype = 2;
    else {
        QMessageBox::information(NULL,"show","<font size=12 >File " +filename + "<br>size: " +Buffer.size() + "<br> has wrong file size </font>"); //<font size=12 > </font>
        return;
    }
    qDebug("filetype = %d", filetype );
    FileBufferIndex = 3;
    for(Address=0x000;Address < 0x018;Address++)
    {
        regvalue = Buffer.at(FileBufferIndex);
        fpga->SynthregSet(Address,regvalue);
        setLCD(Address,regvalue);
        FileBufferIndex++;
    }
    // Env 3
    FileBufferIndex = 0x23;
    for(Address=0x020;Address < 0x028;Address++)
    {
        regvalue = Buffer.at(FileBufferIndex);
        fpga->SynthregSet(Address,regvalue);
        setLCD(Address,regvalue);
        FileBufferIndex++;
    }
    // Env 4
    FileBufferIndex = 0x33;
    for(Address=0x030;Address < 0x038;Address++)
    {
        regvalue = Buffer.at(FileBufferIndex);
        fpga->SynthregSet(Address,regvalue);
        setLCD(Address,regvalue);
        FileBufferIndex++;
    }
    if(filetype == 2){
        // Env 5
        FileBufferIndex = 0x43;
        for(Address=0x040;Address < 0x034;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Env 6
        FileBufferIndex = 0x53;
        for(Address=0x050;Address < 0x058;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Env 7
        FileBufferIndex = 0x63;
        for(Address=0x060;Address < 0x068;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Env 8
        FileBufferIndex = 0x73;
        for(Address=0x070;Address < 0x078;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }

    }
    if(filetype == 1){
        // Osc 1
        FileBufferIndex = 0x43;
        for(Address=0x080;Address < 0x08C;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Osc 2
        FileBufferIndex = 0x53;
        for(Address=0x090;Address < 0x09C;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Osc 3
        FileBufferIndex = 0x63;
        for(Address=0x0A0;Address < 0x0AC;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Osc 4
        FileBufferIndex = 0x73;
        for(Address=0x0B0;Address < 0x0BC;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }

    }
    else if(filetype == 2){
        // Osc 1
        FileBufferIndex = 0x83;
        for(Address=0x080;Address < 0x08C;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Osc 2
        FileBufferIndex = 0x93;
        for(Address=0x090;Address < 0x09C;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Osc 3
        FileBufferIndex = 0xA3;
        for(Address=0x0A0;Address < 0x0AC;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Osc 4
        FileBufferIndex = 0xB3;
        for(Address=0x0B0;Address < 0x0BC;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Osc 5
        FileBufferIndex = 0xC3;
        for(Address=0x0C0;Address < 0x0CC;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Osc 6
        FileBufferIndex = 0xD3;
        for(Address=0x0D0;Address < 0x0DC;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Osc 7
        FileBufferIndex = 0xE3;
        for(Address=0x0E0;Address < 0x0EC;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Osc 8
        FileBufferIndex = 0xF3;
        for(Address=0x0F0;Address < 0x0FC;Address++)
        {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
    }
    // Matrix
    if(filetype == 1){
        // Mod 1
        FileBufferIndex = 0x83;
        for(Address=0x100;Address < 0x104;Address++) {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Fb 1
        FileBufferIndex = 0x8b;
        for(Address=0x108;Address < 0x10c;Address++) {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Mod 2
        FileBufferIndex = 0x93;
        for(Address=0x110;Address < 0x114;Address++) {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Fb 2
        FileBufferIndex = 0x9b;
        for(Address=0x118;Address < 0x11c;Address++) {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Mod 3
        FileBufferIndex = 0xa3;
        for(Address=0x120;Address < 0x124;Address++) {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Fb 3
        FileBufferIndex = 0xab;
        for(Address=0x128;Address < 0x12c;Address++) {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Mod 4
        FileBufferIndex = 0xb3;
        for(Address=0x130;Address < 0x134;Address++) {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
        // Fb 4
        FileBufferIndex = 0xbb;
        for(Address=0x138;Address < 0x13c;Address++) {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
    }
    else if(filetype == 2){
        FileBufferIndex = 0x103;
        for(Address=0x100;Address < 0x180;Address++) {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
    }
    // com
    if (filetype == 1){
        FileBufferIndex = 0xC3;
        for(Address=0x280;Address < 0x287;Address++) {
            regvalue = Buffer.at(FileBufferIndex);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
    }
    else if (filetype == 2){
        FileBufferIndex = 0x283;
        for(Address=0x280;Address < 0x2A0;Address++) {
            regvalue = Buffer.at(FileBufferIndex);
            if(Address >= 0x290) qDebug("read_syx_file name data = %d at address 0x%x", regvalue, Address);
            fpga->SynthregSet(Address,regvalue);
            setLCD(Address,regvalue);
            FileBufferIndex++;
        }
    }
 }

void synth1Tab::write_syx_file(QString filename)
{
    patch_name.clear();
    patch_name.append(filenamelineedit->text());
    QByteArray Buffer = PresetBuffer[cur_save_index];
    Buffer.replace(0x290,patch_name.size(),patch_name);
    Buffer.prepend((char) 0x70);
    Buffer.prepend((char) 0x7D);
    Buffer.prepend((char) 0xF0);
    Buffer.append((char) 0xF7);
    QFile fileB(SYX_FILE_DIR + filename);//
    QMessageBox *msgBox = new QMessageBox;
    msgBox->setText("<font size=12 > Saving preset " + QString::number(cur_save_index+1) +" <br> to file " + filename +"<br>size = "+ QString::number(Buffer.size()) +  "</font>");
    msgBox->setInformativeText("<font size = 8> do you want to save under this filename ? </font>");
    msgBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No | QMessageBox::Cancel);
    msgBox->setStyleSheet("background-color:red");
    int ret = msgBox->exec();
//    QMessageBox::information(NULL,"show","<font size=12 > Saving preset " + QString::number(cur_save_index+1) +" <br> to file " + filename +"<br>size = "+ QString::number(Buffer.size()) +  "</font>");
    if(ret == QMessageBox::Yes)
    {
        if (!fileB.open(QIODevice::WriteOnly))
        {
            QMessageBox::information(NULL,"show","<font size=12 > Failed to open file</font>");
            return;
        }
        fileB.write(Buffer);
        fileB.close();
        populate_fileloadbox();
        presetbutton[active_preset]->setStyleSheet("background-color:red");
    }
    else if (ret == QMessageBox:: No)
    {
//        fileB.close();
        emit keyboard_view();
    }
    else if (ret == QMessageBox:: Cancel)
    {
//        fileB.close();
    }
}

void synth1Tab::filenametext_changed(QString f_name)
{
    QString filename_nowhite;
//    filename_nowhite = filenamelineedit->text();
    filename_nowhite = f_name;
    filename_nowhite.replace( " ","" );
    filenamelineedit->setText(filename_nowhite);
}

MainWindow::~MainWindow()
{
//    delete ui;
}

void MainWindow::quit(void)
{
    close();
}
