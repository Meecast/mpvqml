#ifndef DBUSADAPTOR_H
#define DBUSADAPTOR_H
#include <QDBusAbstractAdaptor>
class DBusAdaptor : public QDBusAbstractAdaptor
{
    Q_OBJECT
    Q_CLASSINFO("D-Bus Interface", "org.meecast.mpvqml")
public:
    explicit DBusAdaptor(QObject *parent = nullptr);
    ~DBusAdaptor();
public slots:
    Q_NOREPLY void openFile(const QStringList &args);
signals:
    void fileOpenRequested(QString path);
};
#endif // DBUSADAPTOR_H
