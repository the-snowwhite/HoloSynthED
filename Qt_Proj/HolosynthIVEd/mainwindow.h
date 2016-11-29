#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QString>
#include <QStringList>

#include "filetab.h"
#include "synth1tab.h"

#include <QWidget>

namespace Ui {
class MainWindow;
}

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    explicit MainWindow(QWidget *parent = 0);
    ~MainWindow();
    QTabWidget* mytabWidget;
    fileTab* ftab1;
    synth1Tab* stab1;
public slots:
    void quit();

private slots:

private:
//    Ui::MainWindow *ui;
//    QTabWidget* mytabWidget;
//    fileTab* tab1;
//    synth1Tab* stab1;
};



#endif // MAINWINDOW_H
