#pragma once

#include "ReminderItem.h"

#include <QAbstractListModel>
#include <QDateTime>
#include <QObject>
#include <QTimer>
#include <QVector>

class TasksModel;
class CustomListsModel;

class RemindersManager : public QObject {
    Q_OBJECT
    Q_PROPERTY(TasksModel* tasksModel READ tasksModel CONSTANT)
    Q_PROPERTY(CustomListsModel* listsModel READ listsModel CONSTANT)

    Q_PROPERTY(int todayCount READ todayCount NOTIFY countsChanged)
    Q_PROPERTY(int scheduledCount READ scheduledCount NOTIFY countsChanged)
    Q_PROPERTY(int allCount READ allCount NOTIFY countsChanged)
    Q_PROPERTY(int flaggedCount READ flaggedCount NOTIFY countsChanged)
    Q_PROPERTY(int completedCount READ completedCount NOTIFY countsChanged)

    Q_PROPERTY(QString currentFilter READ currentFilter NOTIFY currentFilterChanged)
    Q_PROPERTY(QString currentTitle READ currentTitle NOTIFY currentFilterChanged)
    Q_PROPERTY(QString currentColor READ currentColor NOTIFY currentFilterChanged)
    Q_PROPERTY(QString searchQuery READ searchQuery WRITE setSearchQuery NOTIFY searchQueryChanged)

public:
    explicit RemindersManager(QObject *parent = nullptr);
    ~RemindersManager() override;

    TasksModel* tasksModel() const { return m_tasksModel; }
    CustomListsModel* listsModel() const { return m_listsModel; }

    int todayCount() const;
    int scheduledCount() const;
    int allCount() const;
    int flaggedCount() const;
    int completedCount() const;

    QString currentFilter() const { return m_currentFilter; }
    QString currentTitle() const;
    QString currentColor() const;

    QString searchQuery() const { return m_searchQuery; }
    void setSearchQuery(const QString &query);

    // Q_INVOKABLE Actions
    Q_INVOKABLE void selectSmartList(const QString &type);
    Q_INVOKABLE void selectCustomList(const QString &listId);

    Q_INVOKABLE void addReminder(const QString &title, const QString &notes, const QDateTime &dueDate, bool hasDueDate, bool isFlagged, int priority);
    Q_INVOKABLE void toggleCompleted(const QString &id);
    Q_INVOKABLE void toggleFlagged(const QString &id);
    Q_INVOKABLE void updateReminder(const QString &id, const QString &title, const QString &notes, const QDateTime &dueDate, bool hasDueDate, bool isFlagged, int priority);
    Q_INVOKABLE void deleteReminder(const QString &id);

    Q_INVOKABLE void addList(const QString &name, const QString &color, const QString &icon);
    Q_INVOKABLE void deleteList(const QString &listId);

    // Query helpers
    ReminderList getList(const QString &listId) const;
    int countForList(const QString &listId) const;

Q_SIGNALS:
    void countsChanged();
    void currentFilterChanged();
    void searchQueryChanged();

private Q_SLOTS:
    void checkDueNotifications();

private:
    void loadData();
    void saveData();
    void updateFilteredTasks();
    void sendNotification(const ReminderItem &item);

    QString m_currentFilter = QStringLiteral("today"); // "today", "scheduled", "all", "flagged", "completed", or listId
    QString m_searchQuery;

    QVector<ReminderList> m_lists;
    QVector<ReminderItem> m_reminders;
    QVector<ReminderItem> m_filteredReminders;
    QSet<QString> m_notifiedIds;

    TasksModel *m_tasksModel = nullptr;
    CustomListsModel *m_listsModel = nullptr;
    QTimer *m_notifyTimer = nullptr;

    friend class TasksModel;
    friend class CustomListsModel;
};

class TasksModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum TaskRoles {
        IdRole = Qt::UserRole + 1,
        ListIdRole,
        TitleRole,
        NotesRole,
        DueDateRole,
        DueDateStrRole,
        HasDueDateRole,
        IsOverdueRole,
        IsCompletedRole,
        IsFlaggedRole,
        PriorityRole,
        ListColorRole,
        ListNameRole
    };

    explicit TasksModel(RemindersManager *manager, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void refresh();

private:
    RemindersManager *m_manager = nullptr;
};

class CustomListsModel : public QAbstractListModel {
    Q_OBJECT
public:
    enum ListRoles {
        IdRole = Qt::UserRole + 1,
        NameRole,
        ColorRole,
        IconRole,
        CountRole
    };

    explicit CustomListsModel(RemindersManager *manager, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role = Qt::DisplayRole) const override;
    QHash<int, QByteArray> roleNames() const override;

    void refresh();

private:
    RemindersManager *m_manager = nullptr;
};
