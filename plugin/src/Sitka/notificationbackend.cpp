#include "notificationbackend.hpp"

#include <QDBusConnection>
#include <QDBusConnectionInterface>
#include <QDBusPendingReply>
#include <QDBusServiceWatcher>
#include <QDebug>

namespace sitka {
namespace {
const QString notifications = QStringLiteral("org.freedesktop.Notifications");
const QString hokumPath = QStringLiteral("/app/hokum/Daemon");
const QString hokum = QStringLiteral("app.hokum.Daemon");
const QString properties = QStringLiteral("org.freedesktop.DBus.Properties");
const QString dnd = QStringLiteral("DoNotDisturb");
}

NotificationBackend::NotificationBackend(QObject* parent) : QObject(parent) {
    const auto bus = QDBusConnection::sessionBus();
    auto* daemon = bus.interface();
    if (!daemon) return;

    auto* watcher = new QDBusServiceWatcher(notifications, bus, QDBusServiceWatcher::WatchForOwnerChange, this);
    connect(watcher, &QDBusServiceWatcher::serviceOwnerChanged, this,
            [this](const QString&, const QString&, const QString& owner) { watchOwner(owner); });

    const QDBusReply<QStringList> activatable = daemon->call(QStringLiteral("ListActivatableNames"));
    const auto owner = daemon->serviceOwner(notifications);
    // Quickshell's server lives for the process lifetime, even across QML reloads.
    // Select it only at startup, never in the gap while an external daemon restarts.
    mBuiltIn = (owner.isValid() && owner.value() == bus.baseService()) ||
        (owner.error().name() == QStringLiteral("org.freedesktop.DBus.Error.NameHasNoOwner") && activatable.isValid() &&
         !activatable.value().contains(notifications));
    if (mBuiltIn) return;

    if (owner.isValid()) {
        watchOwner(owner.value());
    } else if (activatable.isValid() && activatable.value().contains(notifications)) {
        daemon->asyncCall(QStringLiteral("StartServiceByName"), notifications, uint(0));
    }
}

void NotificationBackend::watchOwner(const QString& owner) {
    if (mBuiltIn || owner == mOwner) return;

    auto bus = QDBusConnection::sessionBus();
    const auto slot = SLOT(propertiesChanged(QString,QVariantMap,QStringList,QDBusMessage));
    if (!mOwner.isEmpty()) bus.disconnect(mOwner, hokumPath, properties, QStringLiteral("PropertiesChanged"), this, slot);
    mOwner = owner;
    if (mHokumAvailable) {
        mHokumAvailable = false;
        mDoNotDisturb = false;
        emit stateChanged();
    }
    if (owner.isEmpty()) return;

    bus.connect(owner, hokumPath, properties, QStringLiteral("PropertiesChanged"), this, slot);
    auto get = QDBusMessage::createMethodCall(owner, hokumPath, properties, QStringLiteral("Get"));
    get << hokum << dnd;
    auto* watcher = new QDBusPendingCallWatcher(bus.asyncCall(get), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, owner](QDBusPendingCallWatcher* call) {
        const QDBusPendingReply<QDBusVariant> reply = *call;
        if (owner == mOwner && reply.isValid()) updateDoNotDisturb(reply.value().variant());
        call->deleteLater();
    });
}

void NotificationBackend::propertiesChanged(const QString& interface, const QVariantMap& changed,
                                            const QStringList&, const QDBusMessage& message) {
    if (interface == hokum && message.service() == mOwner) updateDoNotDisturb(changed.value(dnd));
}

void NotificationBackend::updateDoNotDisturb(const QVariant& value) {
    if (value.metaType().id() != QMetaType::Bool) return;
    if (mHokumAvailable && mDoNotDisturb == value.toBool()) return;
    mHokumAvailable = true;
    mDoNotDisturb = value.toBool();
    emit stateChanged();
}

void NotificationBackend::setDoNotDisturb(bool enabled) {
    if (!mHokumAvailable) return;

    auto request = QDBusMessage::createMethodCall(mOwner, hokumPath, hokum, QStringLiteral("SetDoNotDisturb"));
    request << enabled;
    auto* watcher = new QDBusPendingCallWatcher(QDBusConnection::sessionBus().asyncCall(request), this);
    connect(watcher, &QDBusPendingCallWatcher::finished, this, [this, owner = mOwner](QDBusPendingCallWatcher* call) {
        const QDBusPendingReply<bool> reply = *call;
        if (owner == mOwner) {
            if (reply.isValid()) updateDoNotDisturb(reply.value());
            else qWarning() << "Could not set Hokum Do Not Disturb:" << reply.error().message();
        }
        call->deleteLater();
    });
}

void NotificationBackend::dismissAll() {
    if (!mHokumAvailable) return;
    auto request = QDBusMessage::createMethodCall(mOwner, hokumPath, hokum, QStringLiteral("Dismiss"));
    request << true;
    QDBusConnection::sessionBus().asyncCall(request);
}

} // namespace sitka
