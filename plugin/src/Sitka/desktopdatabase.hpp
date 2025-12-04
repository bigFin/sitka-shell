#pragma once

#include <QObject>
#include <QString>
#include <QStringList>
#include <QMap>
#include <QList>
#include <QMutex>
#include <QUrl>
#include <QtQml/qqmlregistration.h>

namespace sitka {

struct DesktopEntryData {
    Q_GADGET
    Q_PROPERTY(QString id MEMBER id CONSTANT)
    Q_PROPERTY(QString name MEMBER name CONSTANT)
    Q_PROPERTY(QString comment MEMBER comment CONSTANT)
    Q_PROPERTY(QString execString MEMBER execString CONSTANT)
    Q_PROPERTY(QString startupClass MEMBER startupClass CONSTANT)
    Q_PROPERTY(QString genericName MEMBER genericName CONSTANT)
    Q_PROPERTY(QStringList categories MEMBER categories CONSTANT)
    Q_PROPERTY(QStringList keywords MEMBER keywords CONSTANT)
    Q_PROPERTY(QStringList command MEMBER command CONSTANT)
    Q_PROPERTY(QString workingDirectory MEMBER workingDirectory CONSTANT)
    Q_PROPERTY(bool runInTerminal MEMBER runInTerminal CONSTANT)
    Q_PROPERTY(QUrl icon MEMBER icon CONSTANT)
    QML_ELEMENT
    QML_UNCREATABLE("DesktopEntryData is a value type")

public:
    QString id;
    QString name;
    QString comment;
    QString execString;
    QString startupClass;
    QString genericName;
    QStringList categories;
    QStringList keywords;
    QStringList command;
    QString workingDirectory;
    bool runInTerminal = false;
    QUrl icon;
};

class DesktopDatabase : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON
    Q_PROPERTY(QList<QObject*> applications READ applications NOTIFY applicationsChanged)

public:
    explicit DesktopDatabase(QObject* parent = nullptr);
    ~DesktopDatabase();

    QList<QObject*> applications() const;
    Q_INVOKABLE void reload();

signals:
    void applicationsChanged();

private:
    void scan();
    void scanDirectory(const QString& path);
    void parseDesktopFile(const QString& path, const QString& id);

    QList<QObject*> m_apps; // List of DesktopEntryWrapper*
    QMutex m_mutex;
};

// Wrapper for QML access since Q_GADGET in QList isn't fully supported in all QML versions nicely without value type dance
class DesktopEntryWrapper : public QObject {
    Q_OBJECT
    Q_PROPERTY(QString id READ id CONSTANT)
    Q_PROPERTY(QString name READ name CONSTANT)
    Q_PROPERTY(QString comment READ comment CONSTANT)
    Q_PROPERTY(QString execString READ execString CONSTANT)
    Q_PROPERTY(QString startupClass READ startupClass CONSTANT)
    Q_PROPERTY(QString genericName READ genericName CONSTANT)
    Q_PROPERTY(QStringList categories READ categories CONSTANT)
    Q_PROPERTY(QStringList keywords READ keywords CONSTANT)
    Q_PROPERTY(QStringList command READ command CONSTANT)
    Q_PROPERTY(QString workingDirectory READ workingDirectory CONSTANT)
    Q_PROPERTY(bool runInTerminal READ runInTerminal CONSTANT)
    Q_PROPERTY(QUrl icon READ icon CONSTANT)

public:
    explicit DesktopEntryWrapper(const DesktopEntryData& data, QObject* parent = nullptr)
        : QObject(parent), m_data(data) {}

    QString id() const { return m_data.id; }
    QString name() const { return m_data.name; }
    QString comment() const { return m_data.comment; }
    QString execString() const { return m_data.execString; }
    QString startupClass() const { return m_data.startupClass; }
    QString genericName() const { return m_data.genericName; }
    QStringList categories() const { return m_data.categories; }
    QStringList keywords() const { return m_data.keywords; }
    QStringList command() const { return m_data.command; }
    QString workingDirectory() const { return m_data.workingDirectory; }
    bool runInTerminal() const { return m_data.runInTerminal; }
    QUrl icon() const { return m_data.icon; }

private:
    DesktopEntryData m_data;
};

} // namespace sitka
