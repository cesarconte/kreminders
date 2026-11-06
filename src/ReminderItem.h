#pragma once

#include <QDateTime>
#include <QJsonObject>
#include <QString>
#include <QUuid>

struct ReminderItem {
    QString id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    QString listId = QStringLiteral("default");
    QString title;
    QString notes;
    QDateTime dueDate;
    bool hasDueDate = false;
    bool isCompleted = false;
    bool isFlagged = false;
    int priority = 0; // 0=None, 1=Low (!), 2=Medium (!!), 3=High (!!!)
    QDateTime createdDate = QDateTime::currentDateTime();
    QDateTime completedDate;

    QJsonObject toJson() const {
        QJsonObject obj;
        obj[QStringLiteral("id")] = id;
        obj[QStringLiteral("listId")] = listId;
        obj[QStringLiteral("title")] = title;
        obj[QStringLiteral("notes")] = notes;
        obj[QStringLiteral("dueDate")] = dueDate.toString(Qt::ISODate);
        obj[QStringLiteral("hasDueDate")] = hasDueDate;
        obj[QStringLiteral("isCompleted")] = isCompleted;
        obj[QStringLiteral("isFlagged")] = isFlagged;
        obj[QStringLiteral("priority")] = priority;
        obj[QStringLiteral("createdDate")] = createdDate.toString(Qt::ISODate);
        if (completedDate.isValid()) {
            obj[QStringLiteral("completedDate")] = completedDate.toString(Qt::ISODate);
        }
        return obj;
    }

    static ReminderItem fromJson(const QJsonObject &obj) {
        ReminderItem item;
        item.id = obj.value(QStringLiteral("id")).toString(QUuid::createUuid().toString(QUuid::WithoutBraces));
        item.listId = obj.value(QStringLiteral("listId")).toString(QStringLiteral("default"));
        item.title = obj.value(QStringLiteral("title")).toString();
        item.notes = obj.value(QStringLiteral("notes")).toString();
        item.dueDate = QDateTime::fromString(obj.value(QStringLiteral("dueDate")).toString(), Qt::ISODate);
        item.hasDueDate = obj.value(QStringLiteral("hasDueDate")).toBool(false);
        item.isCompleted = obj.value(QStringLiteral("isCompleted")).toBool(false);
        item.isFlagged = obj.value(QStringLiteral("isFlagged")).toBool(false);
        item.priority = obj.value(QStringLiteral("priority")).toInt(0);
        item.createdDate = QDateTime::fromString(obj.value(QStringLiteral("createdDate")).toString(), Qt::ISODate);
        if (obj.contains(QStringLiteral("completedDate"))) {
            item.completedDate = QDateTime::fromString(obj.value(QStringLiteral("completedDate")).toString(), Qt::ISODate);
        }
        return item;
    }
};

struct ReminderList {
    QString id = QUuid::createUuid().toString(QUuid::WithoutBraces);
    QString name = QStringLiteral("Recordatorios");
    QString color = QStringLiteral("#007AFF"); // Apple Blue default
    QString icon = QStringLiteral("list");

    QJsonObject toJson() const {
        QJsonObject obj;
        obj[QStringLiteral("id")] = id;
        obj[QStringLiteral("name")] = name;
        obj[QStringLiteral("color")] = color;
        obj[QStringLiteral("icon")] = icon;
        return obj;
    }

    static ReminderList fromJson(const QJsonObject &obj) {
        ReminderList list;
        list.id = obj.value(QStringLiteral("id")).toString(QUuid::createUuid().toString(QUuid::WithoutBraces));
        list.name = obj.value(QStringLiteral("name")).toString(QStringLiteral("Recordatorios"));
        list.color = obj.value(QStringLiteral("color")).toString(QStringLiteral("#007AFF"));
        list.icon = obj.value(QStringLiteral("icon")).toString(QStringLiteral("list"));
        return list;
    }
};
