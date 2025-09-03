#pragma once

#include <QtQuick/QQuickItem>
#include <qobject.h>
#include <qqmlintegration.h>

class CUtils : public QObject {
    Q_OBJECT;
    QML_NAMED_ELEMENT(CUtils);
    QML_SINGLETON;

public:
<<<<<<< HEAD
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path);
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect);
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved);
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved, QJSValue onFailed);
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved);
<<<<<<< HEAD
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved, QJSValue onFailed);
=======
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path) const;
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect) const;
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved) const;
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, QJSValue onSaved, QJSValue onFailed) const;
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved) const;
    Q_INVOKABLE void saveItem(QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved, QJSValue onFailed) const;
=======
    Q_INVOKABLE void saveItem(
        QQuickItem* target, const QUrl& path, const QRect& rect, QJSValue onSaved, QJSValue onFailed);
>>>>>>> 8b1f2be (internal: format cpp)

    Q_INVOKABLE bool copyFile(const QUrl& source, const QUrl& target) const;
    Q_INVOKABLE bool copyFile(const QUrl& source, const QUrl& target, bool overwrite) const;
<<<<<<< HEAD
>>>>>>> b5d8125 (internal: better copy)
=======

    Q_INVOKABLE void getDominantColour(QQuickItem* item, QJSValue callback);
    Q_INVOKABLE void getDominantColour(QQuickItem* item, int rescaleSize, QJSValue callback);
    Q_INVOKABLE void getDominantColour(const QString& path, QJSValue callback);
    Q_INVOKABLE void getDominantColour(const QString& path, int rescaleSize, QJSValue callback);

    Q_INVOKABLE void getAverageLuminance(QQuickItem* item, QJSValue callback);
    Q_INVOKABLE void getAverageLuminance(QQuickItem* item, int rescaleSize, QJSValue callback);
    Q_INVOKABLE void getAverageLuminance(const QString& path, QJSValue callback);
    Q_INVOKABLE void getAverageLuminance(const QString& path, int rescaleSize, QJSValue callback);

    Q_INVOKABLE QString toLocalFile(const QUrl& url) const;

private:
    QColor findDominantColour(const QImage& image, int rescaleSize) const;
    qreal findAverageLuminance(const QImage& image, int rescaleSize) const;
>>>>>>> 1de2467 (internal: refactor Paths util)
};
