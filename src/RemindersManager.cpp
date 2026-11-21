#include "RemindersManager.h"
#include "DatabaseManager.h"

#include <QApplication>
#include <QClipboard>
#include <QDBusInterface>
#include <QDBusReply>
#include <QPalette>
#include <QRegularExpression>
#include <QStyleHints>

namespace {
QString normalizeTags(const QString &raw)
{
    QStringList out;
    QSet<QString> seen;
    const QStringList parts = raw.split(QRegularExpression(QStringLiteral("[\\s,]+")), Qt::SkipEmptyParts);
    for (QString part : parts) {
        if (!part.startsWith(QLatin1Char('#'))) {
            part.prepend(QLatin1Char('#'));
        }
        if (part.size() > 1 && !seen.contains(part)) {
            seen.insert(part);
            out.append(part);
        }
    }
    return out.join(QLatin1Char(' '));
}
}

RemindersManager::RemindersManager(QObject *parent)
    : QObject(parent)
    , m_tasksModel(new TasksModel(this, this))
    , m_listsModel(new CustomListsModel(this, this))
    , m_notifyTimer(new QTimer(this))
{
    DatabaseManager::instance().init();
    loadLists();
    updateFilteredTasks();

    connect(qApp->styleHints(), &QStyleHints::colorSchemeChanged, this, [this](Qt::ColorScheme) {
        Q_EMIT themeChanged();
    });
    qApp->installEventFilter(this);

    connect(m_notifyTimer, &QTimer::timeout, this, &RemindersManager::checkDueNotifications);
    m_notifyTimer->start(30000); // Check notifications every 30 seconds
}

RemindersManager::~RemindersManager()
{
}

bool RemindersManager::isDark() const
{
    const auto scheme = qApp->styleHints()->colorScheme();
    if (scheme == Qt::ColorScheme::Dark) return true;
    if (scheme == Qt::ColorScheme::Light) return false;
    return qApp->palette().color(QPalette::Window).lightnessF() < 0.5;
}

bool RemindersManager::eventFilter(QObject *watched, QEvent *event)
{
    if (event->type() == QEvent::ApplicationPaletteChange || event->type() == QEvent::PaletteChange || event->type() == QEvent::ThemeChange) {
        Q_EMIT themeChanged();
    }
    return QObject::eventFilter(watched, event);
}

QString RemindersManager::highlightColor() const
{
    return qApp->palette().color(QPalette::Highlight).name();
}

void RemindersManager::loadLists()
{
    m_lists = DatabaseManager::instance().getLists();
}

int RemindersManager::todayCount() const
{
    return DatabaseManager::instance().countToday();
}

int RemindersManager::scheduledCount() const
{
    return DatabaseManager::instance().countScheduled();
}

int RemindersManager::allCount() const
{
    return DatabaseManager::instance().countAll();
}

int RemindersManager::flaggedCount() const
{
    return DatabaseManager::instance().countFlagged();
}

int RemindersManager::urgentCount() const
{
    return DatabaseManager::instance().countUrgent();
}

int RemindersManager::completedCount() const
{
    return DatabaseManager::instance().countCompleted();
}

int RemindersManager::currentViewCompletedCount() const
{
    return DatabaseManager::instance().countCompletedForFilter(m_currentFilter);
}

int RemindersManager::currentViewTotalCount() const
{
    if (m_currentFilter == QStringLiteral("completed")) {
        return m_filteredReminders.size();
    }
    int count = 0;
    for (const auto &item : m_filteredReminders) {
        if (!item.isCompleted) {
            ++count;
        }
    }
    return count;
}

int RemindersManager::countForList(const QString &listId) const
{
    return DatabaseManager::instance().countForList(listId);
}

QStringList RemindersManager::allTags() const
{
    return DatabaseManager::instance().getAllTags();
}

bool RemindersManager::hasGroceriesList() const
{
    for (const auto &l : m_lists) {
        const QString lower = l.name.trimmed().toLower();
        if (lower == QLatin1String("compras") || lower == QLatin1String("groceries")) {
            return true;
        }
    }
    return false;
}

ReminderList RemindersManager::getList(const QString &listId) const
{
    return DatabaseManager::instance().getList(listId);
}

QString RemindersManager::listNameForId(const QString &listId) const
{
    for (const auto &l : m_lists) {
        if (l.id == listId) {
            return l.name;
        }
    }
    return QStringLiteral("Recordatorios");
}

QString RemindersManager::listColorForId(const QString &listId) const
{
    for (const auto &l : m_lists) {
        if (l.id == listId) {
            return l.color;
        }
    }
    return QStringLiteral("#007AFF");
}

QString RemindersManager::currentTitle() const
{
    if (m_currentFilter == QStringLiteral("today")) return QStringLiteral("Hoy");
    if (m_currentFilter == QStringLiteral("scheduled")) return QStringLiteral("Programados");
    if (m_currentFilter == QStringLiteral("all")) return QStringLiteral("Todos");
    if (m_currentFilter == QStringLiteral("flagged")) return QStringLiteral("Con marca");
    if (m_currentFilter == QStringLiteral("urgent")) return QStringLiteral("Urgentes");
    if (m_currentFilter == QStringLiteral("completed")) return QStringLiteral("Completadas");
    if (m_currentFilter == QStringLiteral("tags_all")) return QStringLiteral("Etiquetas");
    if (m_currentFilter.startsWith(QStringLiteral("tag:"))) return m_currentFilter.mid(4);

    for (const auto &l : m_lists) {
        if (l.id == m_currentFilter) return l.name;
    }
    return QStringLiteral("Recordatorios");
}

QString RemindersManager::currentColor() const
{
    if (m_currentFilter == QStringLiteral("today")) return QStringLiteral("#3494FA");
    if (m_currentFilter == QStringLiteral("scheduled")) return QStringLiteral("#E85755");
    if (m_currentFilter == QStringLiteral("all")) return QStringLiteral("#4A4D52");
    if (m_currentFilter == QStringLiteral("flagged")) return QStringLiteral("#EE964B");
    if (m_currentFilter == QStringLiteral("urgent")) return QStringLiteral("#E55882");
    if (m_currentFilter == QStringLiteral("completed")) return QStringLiteral("#6E7885");
    if (m_currentFilter == QStringLiteral("tags_all") || m_currentFilter.startsWith(QStringLiteral("tag:"))) {
        return QStringLiteral("#007AFF");
    }

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

void RemindersManager::setShowCompleted(bool show)
{
    if (m_showCompleted != show) {
        m_showCompleted = show;
        Q_EMIT showCompletedChanged();
        updateFilteredTasks();
    }
}

void RemindersManager::setSortBy(const QString &sortBy)
{
    if (m_sortBy != sortBy) {
        m_sortBy = sortBy;
        Q_EMIT sortByChanged();
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

void RemindersManager::selectTagFilter(const QString &tag)
{
    const QString target = tag.isEmpty() ? QStringLiteral("tags_all") : (QStringLiteral("tag:") + tag);
    if (m_currentFilter != target) {
        m_currentFilter = target;
        Q_EMIT currentFilterChanged();
        updateFilteredTasks();
    }
}

void RemindersManager::updateFilteredTasks()
{
    m_filteredReminders = DatabaseManager::instance().getReminders(m_currentFilter, m_searchQuery, m_showCompleted, m_sortBy);
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
    item.isUrgent = (priority == 3);

    const QString defaultListId = m_lists.isEmpty() ? QStringLiteral("default") : m_lists.first().id;

    if (m_currentFilter == QStringLiteral("today")) {
        item.listId = defaultListId;
        item.hasDueDate = true;
        item.dueDate = QDateTime::currentDateTime();
    } else if (m_currentFilter == QStringLiteral("scheduled")) {
        item.listId = defaultListId;
        item.hasDueDate = true;
        if (!dueDate.isValid()) item.dueDate = QDateTime::currentDateTime().addDays(1);
    } else if (m_currentFilter == QStringLiteral("flagged")) {
        item.listId = defaultListId;
        item.isFlagged = true;
    } else if (m_currentFilter == QStringLiteral("urgent")) {
        item.listId = defaultListId;
        item.isUrgent = true;
    } else if (m_currentFilter.startsWith(QStringLiteral("tag:"))) {
        item.listId = defaultListId;
        item.tags = m_currentFilter.mid(4);
    } else if (m_currentFilter == QStringLiteral("all") || m_currentFilter == QStringLiteral("completed") || m_currentFilter == QStringLiteral("tags_all")) {
        item.listId = defaultListId;
    } else {
        item.listId = m_currentFilter;
    }

    DatabaseManager::instance().addReminder(item);
    updateFilteredTasks();
}

void RemindersManager::toggleCompleted(const QString &id)
{
    DatabaseManager::instance().toggleCompleted(id);
    updateFilteredTasks();
}

void RemindersManager::toggleFlagged(const QString &id)
{
    DatabaseManager::instance().toggleFlagged(id);
    updateFilteredTasks();
}

void RemindersManager::toggleUrgent(const QString &id)
{
    DatabaseManager::instance().toggleUrgent(id);
    updateFilteredTasks();
}

void RemindersManager::updateReminder(const QString &id, const QString &title, const QString &notes, const QDateTime &dueDate, bool hasDueDate, bool isFlagged, int priority)
{
    DatabaseManager::instance().updateReminder(id, title.trimmed(), notes.trimmed(), dueDate, hasDueDate, isFlagged, priority);
    updateFilteredTasks();
}

void RemindersManager::updateReminderDetails(const QString &id, const QString &listId, const QString &title, const QString &notes, const QDateTime &dueDate, bool hasDueDate, bool isFlagged, bool isUrgent, int priority, const QString &tags, bool hasDueTime, bool hasLocation, bool whenMessaging)
{
    const QString targetListId = listId.isEmpty() ? (m_lists.isEmpty() ? QStringLiteral("default") : m_lists.first().id) : listId;
    DatabaseManager::instance().updateReminderFull(
        id,
        targetListId,
        title.trimmed(),
        notes.trimmed(),
        dueDate,
        hasDueDate,
        isFlagged,
        isUrgent,
        priority,
        normalizeTags(tags),
        hasDueTime,
        hasLocation,
        whenMessaging
    );
    updateFilteredTasks();
}

void RemindersManager::deleteReminder(const QString &id)
{
    DatabaseManager::instance().deleteReminder(id);
    updateFilteredTasks();
}

void RemindersManager::clearCompletedInCurrentView()
{
    DatabaseManager::instance().clearCompletedForFilter(m_currentFilter);
    updateFilteredTasks();
}

void RemindersManager::copyCurrentListToClipboard()
{
    QStringList lines;
    lines.append(currentTitle() + QStringLiteral(":"));
    for (const auto &item : m_filteredReminders) {
        const QString prefix = item.isCompleted ? QStringLiteral("[x] ") : QStringLiteral("[ ] ");
        QString line = prefix + item.title;
        if (!item.notes.isEmpty()) {
            line += QStringLiteral(" — ") + item.notes;
        }
        if (!item.tags.isEmpty()) {
            line += QStringLiteral(" ") + item.tags;
        }
        lines.append(line);
    }
    if (auto *cb = QApplication::clipboard()) {
        cb->setText(lines.join(QLatin1Char('\n')));
    }
}

void RemindersManager::addList(const QString &name, const QString &color, const QString &icon)
{
    ReminderList list;
    list.name = name.trimmed();
    list.color = color;
    list.icon = icon;

    DatabaseManager::instance().addList(list);
    loadLists();
    m_listsModel->refresh();
    Q_EMIT countsChanged();

    selectCustomList(list.id);
}

void RemindersManager::deleteList(const QString &listId)
{
    DatabaseManager::instance().deleteList(listId);
    loadLists();

    if (m_currentFilter == listId) {
        selectSmartList(QStringLiteral("today"));
    } else {
        updateFilteredTasks();
    }
}

void RemindersManager::checkDueNotifications()
{
    const auto due = DatabaseManager::instance().getDueReminders(QDateTime::currentDateTime());
    for (const auto &item : due) {
        if (!m_notifiedIds.contains(item.id)) {
            sendNotification(item);
            m_notifiedIds.insert(item.id);
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
        if (!item.hasDueDate || !item.dueDate.isValid()) return QString();
        const QDate today = QDate::currentDate();
        const QString timeSuffix = item.hasDueTime ? QString(QStringLiteral(", ") + item.dueDate.toString(QStringLiteral("HH:mm"))) : QString();
        if (item.dueDate.date() == today) {
            return QString(QStringLiteral("Hoy") + timeSuffix);
        } else if (item.dueDate.date() == today.addDays(1)) {
            return QString(QStringLiteral("Mañana") + timeSuffix);
        }
        return QString(item.dueDate.toString(QStringLiteral("d MMM yyyy")) + timeSuffix);
    }
    case HasDueDateRole: return item.hasDueDate;
    case HasDueTimeRole: return item.hasDueTime;
    case IsOverdueRole:
        return item.hasDueDate && !item.isCompleted && item.dueDate.isValid() &&
            (item.hasDueTime ? (item.dueDate < QDateTime::currentDateTime()) : (item.dueDate.date() < QDate::currentDate()));
    case IsCompletedRole: return item.isCompleted;
    case IsFlaggedRole: return item.isFlagged;
    case IsUrgentRole: return item.isUrgent;
    case PriorityRole: return item.priority;
    case TagsRole: return item.tags;
    case HasLocationRole: return item.hasLocation;
    case WhenMessagingRole: return item.whenMessaging;
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
        {HasDueTimeRole, "hasDueTime"},
        {IsOverdueRole, "isOverdue"},
        {IsCompletedRole, "isCompleted"},
        {IsFlaggedRole, "isFlagged"},
        {IsUrgentRole, "isUrgent"},
        {PriorityRole, "priority"},
        {TagsRole, "tags"},
        {HasLocationRole, "hasLocation"},
        {WhenMessagingRole, "whenMessaging"},
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
