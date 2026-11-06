#pragma once

#include "ReminderItem.h"

#include <QDateTime>
#include <QSqlDatabase>
#include <QString>
#include <QVector>

class DatabaseManager {
public:
    static DatabaseManager& instance();

    bool init();

    // Lists
    QVector<ReminderList> getLists();
    ReminderList getList(const QString &listId);
    bool addList(const ReminderList &list);
    bool deleteList(const QString &listId);

    // Reminders
    QVector<ReminderItem> getReminders(const QString &filter, const QString &searchQuery = QString());
    ReminderItem getReminder(const QString &id);
    bool addReminder(const ReminderItem &item);
    bool updateReminder(const ReminderItem &item);
    bool updateReminder(const QString &id, const QString &title, const QString &notes, const QDateTime &dueDate, bool hasDueDate, bool isFlagged, int priority);
    bool toggleCompleted(const QString &id);
    bool toggleFlagged(const QString &id);
    bool deleteReminder(const QString &id);

    // Counts
    int countToday();
    int countScheduled();
    int countAll();
    int countFlagged();
    int countCompleted();
    int countForList(const QString &listId);

    // Notifications
    QVector<ReminderItem> getDueReminders(const QDateTime &now);

private:
    DatabaseManager() = default;
    ~DatabaseManager() = default;
    DatabaseManager(const DatabaseManager&) = delete;
    DatabaseManager& operator=(const DatabaseManager&) = delete;

    void migrateFromJsonIfNeeded();
    QSqlDatabase m_db;
};
