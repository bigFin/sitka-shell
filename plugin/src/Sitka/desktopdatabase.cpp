#include "desktopdatabase.hpp"

#include <QStandardPaths>
#include <QDirIterator>
#include <QSettings>
#include <QDebug>
#include <QProcess>
#include <QtConcurrent>
#include <QRegularExpression>

namespace sitka {

DesktopDatabase::DesktopDatabase(QObject* parent) : QObject(parent) {
    // Run scan in background to avoid blocking startup
    QThreadPool::globalInstance()->start([this] {
        scan();
    });
}

DesktopDatabase::~DesktopDatabase() {
    qDeleteAll(m_apps);
}

QList<QObject*> DesktopDatabase::applications() const {
    return m_apps;
}

void DesktopDatabase::reload() {
    QThreadPool::globalInstance()->start([this] {
        scan();
    });
}

void DesktopDatabase::scan() {
    QList<QObject*> newApps;
    const QStringList dirs = QStandardPaths::standardLocations(QStandardPaths::ApplicationsLocation);

    QSet<QString> seenIds;

    for (const QString& dirPath : dirs) {
        if (!QDir(dirPath).exists()) continue;

        QDirIterator it(dirPath, QStringList() << "*.desktop", QDir::Files, QDirIterator::Subdirectories);
        while (it.hasNext()) {
            const QString path = it.next();
            
            // Calculate ID based on XDG spec (relative path, slash to dash)
            QString relPath = QDir(dirPath).relativeFilePath(path);
            QString id = relPath.replace("/", "-");

            if (seenIds.contains(id)) continue;
            seenIds.insert(id);

            QSettings settings(path, QSettings::IniFormat);
            settings.beginGroup("Desktop Entry");

            if (settings.value("Hidden", false).toBool() || settings.value("NoDisplay", false).toBool()) {
                continue;
            }
            
            // Type must be Application
            if (settings.value("Type").toString() != "Application") {
                continue;
            }

            // Basic validation for Wine entries: if Icon is invalid, we might want to skip or use default?
            // We'll just proceed, but we won't crash.

            DesktopEntryData data;
            data.id = id;
            data.name = settings.value("Name").toString();
            data.comment = settings.value("Comment").toString();
            data.execString = settings.value("Exec").toString();
            data.startupClass = settings.value("StartupWMClass").toString();
            data.genericName = settings.value("GenericName").toString();
            data.categories = settings.value("Categories").toString().split(";", Qt::SkipEmptyParts);
            data.keywords = settings.value("Keywords").toString().split(";", Qt::SkipEmptyParts);
            data.workingDirectory = settings.value("Path").toString();
            data.runInTerminal = settings.value("Terminal", false).toBool();

            QString iconStr = settings.value("Icon").toString();
            if (iconStr.startsWith("/")) {
                data.icon = QUrl::fromLocalFile(iconStr);
            } else if (!iconStr.isEmpty()) {
                data.icon = QUrl(iconStr); // Theme icon name
            }
            
            // Parse Exec command
            QString exec = data.execString;
            if (exec.isEmpty()) continue;

            // Remove field codes like %f, %u, %i, %c, %k
            exec.remove(QRegularExpression("%[fFuUick]"));
            
            // Qt 6 has QProcess::splitCommand
            // Qt 5 doesn't have static splitCommand.
            // Since we are on 6.10, we can use it.
            QStringList args = QProcess::splitCommand(exec);
            if (!args.isEmpty()) {
                data.command = args;
                newApps.append(new DesktopEntryWrapper(data));
            }
        }
    }

    // Update model on main thread
    QMetaObject::invokeMethod(this, [this, newApps]() mutable {
        QMutexLocker locker(&m_mutex);
        qDeleteAll(m_apps);
        m_apps = newApps;
        emit applicationsChanged();
    });
}

} // namespace sitka
