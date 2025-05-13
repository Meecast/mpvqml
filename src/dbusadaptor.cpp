#include <QUrl>
#include <QStringList>
#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDebug>
#include "dbusadaptor.h"
const QString dbusServiceStr = QStringLiteral("org.meecast.mpvqml");
const QString dbusPathStr = QStringLiteral("/org/meecast/mpvqml");
DBusAdaptor::DBusAdaptor(QObject *parent) : QDBusAbstractAdaptor(parent)
{
    QDBusConnection dbusConnection = QDBusConnection::sessionBus();
    if (!dbusConnection.interface()->isServiceRegistered(dbusServiceStr)) {
        dbusConnection.registerObject(dbusPathStr, parent);
        dbusConnection.registerService(dbusServiceStr);
    }
}
DBusAdaptor::~DBusAdaptor()
{
    QDBusConnection dbusConnection = QDBusConnection::sessionBus();
    dbusConnection.unregisterObject(dbusPathStr);
    dbusConnection.unregisterService(dbusServiceStr);
}
/*!
 * Define DBus interface method that will be called when this application is chosen
 * to open file with a relevant MIME type.
 * \param List of file URIs the application is requested to open.
 */
void DBusAdaptor::openFile(const QStringList &args)
{
    qDebug() << args;
    if (args.isEmpty())
        return;
    QString path;
    for (const auto &arg : args) {
        if (arg.isEmpty())
            continue;
        path = arg;
        break;
    }
    path = QUrl::fromPercentEncoding(path.toUtf8());
    path.remove(QStringLiteral("file://"));
    qDebug() << path;
    // Pass the list of file paths to the qml context.
    emit fileOpenRequested(path);
}

