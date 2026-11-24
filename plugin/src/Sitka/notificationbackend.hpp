#pragma once

#include <QDBusMessage>
#include <QObject>
#include <QVariantMap>
#include <qqmlintegration.h>

namespace sitka {

class NotificationBackend : public QObject {
    Q_OBJECT
    QML_ELEMENT
    Q_PROPERTY(bool builtIn READ builtIn CONSTANT)
    Q_PROPERTY(bool hokumAvailable READ hokumAvailable NOTIFY stateChanged)
    Q_PROPERTY(bool doNotDisturb READ doNotDisturb NOTIFY stateChanged)

public:
    explicit NotificationBackend(QObject* parent = nullptr);

    bool builtIn() const { return mBuiltIn; }
    bool hokumAvailable() const { return mHokumAvailable; }
    bool doNotDisturb() const { return mDoNotDisturb; }

    Q_INVOKABLE void setDoNotDisturb(bool enabled);
    Q_INVOKABLE void dismissAll();

signals:
    void stateChanged();

private slots:
    void propertiesChanged(const QString& interface, const QVariantMap& changed,
                           const QStringList& invalidated, const QDBusMessage& message);

private:
    void watchOwner(const QString& owner);
    void updateDoNotDisturb(const QVariant& value);

    QString mOwner;
    bool mBuiltIn = false;
    bool mHokumAvailable = false;
    bool mDoNotDisturb = false;
};

} // namespace sitka
