#include "RemindersManager.h"

#include <QDBusInterface>
#include <QDBusReply>
#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QStandardPaths>

RemindersManager::RemindersManager(QObject *parent)
    : QObject(parent)
    , m_tasksModel(new TasksModel(this, this))
    , m_listsModel(new CustomListsModel(this, this))
    , m_notifyTimer(new QTimer(this))
{
    loadData();
    updateFilteredTasks();

    connect(m_notifyTimer, &QTimer::timeout, this, &RemindersManager::checkDueNotifications);
    m_notifyTimer->start(30000); // Check every 30 seconds
}

RemindersManager::~RemindersManager()
{
    saveData();
}

void RemindersManager::loadData()
{
    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    const QString filePath = dataDir + QStringLiteral("/reminders.json");

    QFile file(filePath);
    if (file.open(QIODevice::ReadOnly)) {
        const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
        const QJsonObject root = doc.object();

        m_lists.clear();
        const QJsonArray listsArray = root.value(QStringLiteral("lists")).toArray();
        for (const auto &val : listsArray) {
            m_lists.append(ReminderList::fromJson(val.toObject()));
        }

        m_reminders.clear();
        const QJsonArray remindersArray = root.value(QStringLiteral("reminders")).toArray();
        for (const auto &val : remindersArray) {
            m_reminders.append(ReminderItem::fromJson(val.toObject()));
        }
    }

    if (m_lists.isEmpty()) {
        ReminderList defaultList;
        defaultList.id = QStringLiteral("default");
        defaultList.name = QStringLiteral("Recordatorios");
        defaultList.color = QStringLiteral("#007AFF");
        defaultList.icon = QStringLiteral("list");
        m_lists.append(defaultList);

        ReminderList personalList;
        personalList.id = QStringLiteral("personal");
        personalList.name = QStringLiteral("Personal");
        personalList.color = QStringLiteral("#FF9500");
        personalList.icon = QStringLiteral("user");
        m_lists.append(personalList);

        ReminderList workList;
        workList.id = QStringLiteral("work");
        workList.name = QStringLiteral("Trabajo");
        workList.color = QStringLiteral("#34C759");
        workList.icon = QStringLiteral("briefcase");
        m_lists.append(workList);

        // Sample tasks for initial out-of-the-box delight
        ReminderItem sample1;
        sample1.listId = QStringLiteral("default");
        sample1.title = QStringLiteral("Probar la nueva app Recordatorios");
        sample1.notes = QStringLiteral("Diseño 1:1 con macOS Golden Gate en KDE Plasma 6");
        sample1.hasDueDate = true;
        sample1.dueDate = QDateTime::currentDateTime();
        sample1.isFlagged = true;
        sample1.priority = 2;
        m_reminders.append(sample1);

        ReminderItem sample2;
        sample2.listId = QStringLiteral("default");
        sample2.title = QStringLiteral("Organizar lista de compras");
        sample2.notes = QStringLiteral("Frutas, café y pan");
        sample2.hasDueDate = false;
        m_reminders.append(sample2);

        saveData();
    }
}

void RemindersManager::saveData()
{
    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    const QString filePath = dataDir + QStringLiteral("/reminders.json");

    QJsonObject root;
    QJsonArray listsArray;
    for (const auto &list : m_lists) {
        listsArray.append(list.toJson());
    }
    root[QStringLiteral("lists")] = listsArray;

    QJsonArray remindersArray;
    for (const auto &item : m_reminders) {
        remindersArray.append(item.toJson());
    }
    root[QStringLiteral("reminders")] = remindersArray;

    QFile file(filePath);
    if (file.open(QIODevice::WriteOnly)) {
        file.write(QJsonDocument(root).toJson(QJsonDocument::Indented));
    }
}

int RemindersManager::todayCount() const
{
    const QDate today = QDate::currentDate();
    int count = 0;
    for (const auto &item : m_reminders) {
        if (!item.isCompleted && item.hasDueDate && item.dueDate.date() == today) {
            count++;
        }
    }
    return count;
}

int RemindersManager::scheduledCount() const
{
    int count = 0;
    for (const auto &item : m_reminders) {
        if (!item.isCompleted && item.hasDueDate) {
            count++;
        }
    }
    return count;
}

int RemindersManager::allCount() const
{
    int count = 0;
    for (const auto &item : m_reminders) {
        if (!item.isCompleted) {
            count++;
        }
    }
    return count;
}

int RemindersManager::flaggedCount() const
{
    int count = 0;
    for (const auto &item : m_reminders) {
        if (!item.isCompleted && item.isFlagged) {
            count++;
        }
    }
    return count;
}

int RemindersManager::completedCount() const
{
    int count = 0;
    for (const auto &item : m_reminders) {
        if (item.isCompleted) {
            count++;
        }
    }
    return count;
}

int RemindersManager::countForList(const QString &listId) const
{
    int count = 0;
    for (const auto &item : m_reminders) {
        if (!item.isCompleted && item.listId == listId) {
            count++;
        }
    }
    return count;
}

ReminderList RemindersManager::getList(const QString &listId) const
{
    for (const auto &l : m_lists) {
        if (l.id == listId) return l;
    }
    return ReminderList{};
}

QString RemindersManager::currentTitle() const
{
    if (m_currentFilter == QStringLiteral("today")) return QStringLiteral("Hoy");
    if (m_currentFilter == QStringLiteral("scheduled")) return QStringLiteral("Programados");
    if (m_currentFilter == QStringLiteral("all")) return QStringLiteral("Todos");
    if (m_currentFilter == QStringLiteral("flagged")) return QStringLiteral("Con marca");
    if (m_currentFilter == QStringLiteral("completed")) return QStringLiteral("Completadas");

    for (const auto &l : m_lists) {
        if (l.id == m_currentFilter) return l.name;
    }
    return QStringLiteral("Recordatorios");
}

QString RemindersManager::currentColor() const
{
    if (m_currentFilter == QStringLiteral("today")) return QStringLiteral("#007AFF");
    if (m_currentFilter == QStringLiteral("scheduled")) return QStringLiteral("#FF3B30");
    if (m_currentFilter == QStringLiteral("all")) return QStringLiteral("#5856D6");
    if (m_currentFilter == QStringLiteral("flagged")) return QStringLiteral("#FF9500");
    if (m_currentFilter == QStringLiteral("completed")) return QStringLiteral("#34C759");

    for (const auto &l : m_lists) {
        if (l.id == m_currentFilter) return l.color;
    }
    return QStringLiteral("#007AFF");
}

void RemindersManager::setSearchQuery(const QString &query)
{
    if (m_searchQuery != query) {
        m_searchQuery = query;
        Q_EMIT searchQueryChanged();
        updateFilteredTasks();
    }
}

void RemindersManager::selectSmartList(const QString &type)
{
    if (m_currentFilter != type) {
        m_currentFilter = type;
        Q_EMIT currentFilterChanged();
        updateFilteredTasks();
    }
}

void RemindersManager::selectCustomList(const QString &listId)
{
    if (m_currentFilter != listId) {
        m_currentFilter = listId;
        Q_EMIT currentFilterChanged();
        updateFilteredTasks();
    }
}

void RemindersManager::updateFilteredTasks()
{
    m_filteredReminders.clear();
    const QDate today = QDate::currentDate();

    for (const auto &item : m_reminders) {
        if (!m_searchQuery.isEmpty()) {
            if (!item.title.contains(m_searchQuery, Qt::CaseInsensitive) &&
                !item.notes.contains(m_searchQuery, Qt::CaseInsensitive)) {
                continue;
            }
        }

        if (m_currentFilter == QStringLiteral("today")) {
            if (!item.isCompleted && item.hasDueDate && item.dueDate.date() == today) {
                m_filteredReminders.append(item);
            }
        } else if (m_currentFilter == QStringLiteral("scheduled")) {
            if (!item.isCompleted && item.hasDueDate) {
                m_filteredReminders.append(item);
            }
        } else if (m_currentFilter == QStringLiteral("all")) {
            if (!item.isCompleted) {
                m_filteredReminders.append(item);
            }
        } else if (m_currentFilter == QStringLiteral("flagged")) {
            if (!item.isCompleted && item.isFlagged) {
                m_filteredReminders.append(item);
            }
        } else if (m_currentFilter == QStringLiteral("completed")) {
            if (item.isCompleted) {
                m_filteredReminders.append(item);
            }
        } else {
            // Specific Custom List
            if (item.listId == m_currentFilter) {
                m_filteredReminders.append(item);
            }
        }
    }

    m_tasksModel->refresh();
    m_listsModel->refresh();
    Q_EMIT countsChanged();
}

void RemindersManager::addReminder(const QString &title, const QString &notes, const QDateTime &dueDate, bool hasDueDate, bool isFlagged, int priority)
{
    ReminderItem item;
    item.title = title.trimmed();
    item.notes = notes.trimmed();
    item.dueDate = dueDate;
    item.hasDueDate = hasDueDate;
    item.isFlagged = isFlagged;
    item.priority = priority;

    if (m_currentFilter == QStringLiteral("today")) {
        item.listId = m_lists.isEmpty() ? QStringLiteral("default") : m_lists.first().id;
        item.hasDueDate = true;
        item.dueDate = QDateTime::currentDateTime();
    } else if (m_currentFilter == QStringLiteral("scheduled")) {
        item.listId = m_lists.isEmpty() ? QStringLiteral("default") : m_lists.first().id;
        item.hasDueDate = true;
        if (!dueDate.isValid()) item.dueDate = QDateTime::currentDateTime().addDays(1);
    } else if (m_currentFilter == QStringLiteral("flagged")) {
        item.listId = m_lists.isEmpty() ? QStringLiteral("default") : m_lists.first().id;
        item.isFlagged = true;
    } else if (m_currentFilter == QStringLiteral("all") || m_currentFilter == QStringLiteral("completed")) {
        item.listId = m_lists.isEmpty() ? QStringLiteral("default") : m_lists.first().id;
    } else {
        item.listId = m_currentFilter;
    }

    m_reminders.prepend(item);
    saveData();
    updateFilteredTasks();
}

void RemindersManager::toggleCompleted(const QString &id)
{
    for (auto &item : m_reminders) {
        if (item.id == id) {
            item.isCompleted = !item.isCompleted;
            item.completedDate = item.isCompleted ? QDateTime::currentDateTime() : QDateTime();
            break;
        }
    }
    saveData();
    updateFilteredTasks();
}

void RemindersManager::toggleFlagged(const QString &id)
{
    for (auto &item : m_reminders) {
        if (item.id == id) {
            item.isFlagged = !item.isFlagged;
            break;
        }
    }
    saveData();
    updateFilteredTasks();
}

void RemindersManager::updateReminder(const QString &id, const QString &title, const QString &notes, const QDateTime &dueDate, bool hasDueDate, bool isFlagged, int priority)
{
    for (auto &item : m_reminders) {
        if (item.id == id) {
            item.title = title.trimmed();
            item.notes = notes.trimmed();
            item.dueDate = dueDate;
            item.hasDueDate = hasDueDate;
            item.isFlagged = isFlagged;
            item.priority = priority;
            break;
        }
    }
    saveData();
    updateFilteredTasks();
}

void RemindersManager::deleteReminder(const QString &id)
{
    for (int i = 0; i < m_reminders.size(); ++i) {
        if (m_reminders[i].id == id) {
            m_reminders.removeAt(i);
            break;
        }
    }
    saveData();
    updateFilteredTasks();
}

void RemindersManager::addList(const QString &name, const QString &color, const QString &icon)
{
    ReminderList list;
    list.name = name.trimmed();
    list.color = color;
    list.icon = icon;
    m_lists.append(list);

    saveData();
    m_listsModel->refresh();
    Q_EMIT countsChanged();

    selectCustomList(list.id);
}

void RemindersManager::deleteList(const QString &listId)
{
    for (int i = 0; i < m_lists.size(); ++i) {
        if (m_lists[i].id == listId) {
            m_lists.removeAt(i);
            break;
        }
    }
    // Remove tasks associated with this list
    m_reminders.removeIf([&listId](const ReminderItem &item) {
        return item.listId == listId;
    });

    saveData();
    if (m_currentFilter == listId) {
        selectSmartList(QStringLiteral("today"));
    } else {
        updateFilteredTasks();
    }
}

void RemindersManager::checkDueNotifications()
{
    const QDateTime now = QDateTime::currentDateTime();
    for (const auto &item : m_reminders) {
        if (!item.isCompleted && item.hasDueDate && item.dueDate <= now) {
            if (!m_notifiedIds.contains(item.id)) {
                sendNotification(item);
                m_notifiedIds.insert(item.id);
            }
        }
    }
}

void RemindersManager::sendNotification(const ReminderItem &item)
{
    QDBusInterface notify(QStringLiteral("org.freedesktop.Notifications"),
                         QStringLiteral("/org/freedesktop/Notifications"),
                         QStringLiteral("org.freedesktop.Notifications"),
                         QDBusConnection::sessionBus());

    if (notify.isValid()) {
        QVariantMap hints;
        notify.call(QStringLiteral("Notify"),
                    QStringLiteral("kreminders"),
                    (uint)0,
                    QStringLiteral("reminders"),
                    item.title,
                    item.notes.isEmpty() ? QStringLiteral("Recordatorio de tareas") : item.notes,
                    QStringList{},
                    hints,
                    (int)5000);
    }
}

// -----------------------------------------------------------------------------
// TasksModel Implementation
// -----------------------------------------------------------------------------
TasksModel::TasksModel(RemindersManager *manager, QObject *parent)
    : QAbstractListModel(parent)
    , m_manager(manager)
{
}

int TasksModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid() || !m_manager) return 0;
    return m_manager->m_filteredReminders.size();
}

QVariant TasksModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || !m_manager || index.row() >= m_manager->m_filteredReminders.size()) {
        return QVariant();
    }

    const auto &item = m_manager->m_filteredReminders.at(index.row());
    const auto list = m_manager->getList(item.listId);

    switch (role) {
    case IdRole: return item.id;
    case ListIdRole: return item.listId;
    case TitleRole: return item.title;
    case NotesRole: return item.notes;
    case DueDateRole: return item.dueDate;
    case DueDateStrRole: {
        if (!item.hasDueDate) return QString();
        const QDate today = QDate::currentDate();
        if (item.dueDate.date() == today) {
            return QString(QStringLiteral("Hoy, ") + item.dueDate.toString(QStringLiteral("HH:mm")));
        } else if (item.dueDate.date() == today.addDays(1)) {
            return QString(QStringLiteral("Mañana, ") + item.dueDate.toString(QStringLiteral("HH:mm")));
        }
        return item.dueDate.toString(QStringLiteral("d MMM yyyy, HH:mm"));
    }
    case HasDueDateRole: return item.hasDueDate;
    case IsOverdueRole: return item.hasDueDate && !item.isCompleted && item.dueDate < QDateTime::currentDateTime();
    case IsCompletedRole: return item.isCompleted;
    case IsFlaggedRole: return item.isFlagged;
    case PriorityRole: return item.priority;
    case ListColorRole: return list.color.isEmpty() ? QStringLiteral("#007AFF") : list.color;
    case ListNameRole: return list.name.isEmpty() ? QStringLiteral("Recordatorios") : list.name;
    default: return QVariant();
    }
}

QHash<int, QByteArray> TasksModel::roleNames() const
{
    return {
        {IdRole, "id"},
        {ListIdRole, "listId"},
        {TitleRole, "title"},
        {NotesRole, "notes"},
        {DueDateRole, "dueDate"},
        {DueDateStrRole, "dueDateStr"},
        {HasDueDateRole, "hasDueDate"},
        {IsOverdueRole, "isOverdue"},
        {IsCompletedRole, "isCompleted"},
        {IsFlaggedRole, "isFlagged"},
        {PriorityRole, "priority"},
        {ListColorRole, "listColor"},
        {ListNameRole, "listName"}
    };
}

void TasksModel::refresh()
{
    beginResetModel();
    endResetModel();
}

// -----------------------------------------------------------------------------
// CustomListsModel Implementation
// -----------------------------------------------------------------------------
CustomListsModel::CustomListsModel(RemindersManager *manager, QObject *parent)
    : QAbstractListModel(parent)
    , m_manager(manager)
{
}

int CustomListsModel::rowCount(const QModelIndex &parent) const
{
    if (parent.isValid() || !m_manager) return 0;
    return m_manager->m_lists.size();
}

QVariant CustomListsModel::data(const QModelIndex &index, int role) const
{
    if (!index.isValid() || !m_manager || index.row() >= m_manager->m_lists.size()) {
        return QVariant();
    }

    const auto &list = m_manager->m_lists.at(index.row());

    switch (role) {
    case IdRole: return list.id;
    case NameRole: return list.name;
    case ColorRole: return list.color;
    case IconRole: return list.icon;
    case CountRole: return m_manager->countForList(list.id);
    default: return QVariant();
    }
}

QHash<int, QByteArray> CustomListsModel::roleNames() const
{
    return {
        {IdRole, "id"},
        {NameRole, "name"},
        {ColorRole, "color"},
        {IconRole, "icon"},
        {CountRole, "count"}
    };
}

void CustomListsModel::refresh()
{
    beginResetModel();
    endResetModel();
}
