#include "DatabaseManager.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QVariant>
#include <QtLogging>

DatabaseManager& DatabaseManager::instance()
{
    static DatabaseManager mgr;
    return mgr;
}

bool DatabaseManager::init()
{
    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    QDir().mkpath(dataDir);
    const QString dbPath = dataDir + QStringLiteral("/reminders.sqlite");

    m_db = QSqlDatabase::addDatabase(QStringLiteral("QSQLITE"));
    m_db.setDatabaseName(dbPath);

    if (!m_db.open()) {
        qWarning() << "Failed to open SQLite database:" << m_db.lastError().text();
        return false;
    }

    QSqlQuery q;
    q.exec(QStringLiteral("PRAGMA journal_mode=WAL;"));
    q.exec(QStringLiteral("PRAGMA synchronous=NORMAL;"));
    q.exec(QStringLiteral("PRAGMA foreign_keys=ON;"));

    // Create Tables
    q.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS lists ("
        "  id TEXT PRIMARY KEY,"
        "  name TEXT NOT NULL,"
        "  color TEXT NOT NULL,"
        "  icon TEXT NOT NULL,"
        "  position INTEGER DEFAULT 0"
        ");"
    ));

    q.exec(QStringLiteral(
        "CREATE TABLE IF NOT EXISTS reminders ("
        "  id TEXT PRIMARY KEY,"
        "  list_id TEXT NOT NULL REFERENCES lists(id) ON DELETE CASCADE,"
        "  title TEXT NOT NULL,"
        "  notes TEXT,"
        "  due_date TEXT,"
        "  has_due_date INTEGER DEFAULT 0,"
        "  is_completed INTEGER DEFAULT 0,"
        "  is_flagged INTEGER DEFAULT 0,"
        "  priority INTEGER DEFAULT 0,"
        "  created_date TEXT,"
        "  completed_date TEXT"
        ");"
    ));

    // Create Indices
    q.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS idx_reminders_list ON reminders(list_id);"));
    q.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS idx_reminders_due ON reminders(has_due_date, is_completed, due_date);"));
    q.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS idx_reminders_flagged ON reminders(is_flagged, is_completed);"));
    q.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS idx_reminders_completed ON reminders(is_completed);"));

    migrateFromJsonIfNeeded();

    // Default lists if totally empty
    q.exec(QStringLiteral("SELECT COUNT(*) FROM lists;"));
    if (q.next() && q.value(0).toInt() == 0) {
        ReminderList defaultList{QStringLiteral("default"), QStringLiteral("Recordatorios"), QStringLiteral("#007AFF"), QStringLiteral("list")};
        ReminderList personalList{QStringLiteral("personal"), QStringLiteral("Personal"), QStringLiteral("#FF9500"), QStringLiteral("user")};
        ReminderList workList{QStringLiteral("work"), QStringLiteral("Trabajo"), QStringLiteral("#34C759"), QStringLiteral("briefcase")};
        addList(defaultList);
        addList(personalList);
        addList(workList);

        ReminderItem sample1;
        sample1.listId = QStringLiteral("default");
        sample1.title = QStringLiteral("Probar la nueva app Recordatorios");
        sample1.notes = QStringLiteral("Diseño 1:1 con macOS Golden Gate en KDE Plasma 6 (SQLite)");
        sample1.hasDueDate = true;
        sample1.dueDate = QDateTime::currentDateTime();
        sample1.isFlagged = true;
        sample1.priority = 2;
        addReminder(sample1);
    }

    return true;
}

void DatabaseManager::migrateFromJsonIfNeeded()
{
    const QString dataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
    const QString jsonPath = dataDir + QStringLiteral("/reminders.json");

    if (!QFile::exists(jsonPath)) {
        return;
    }

    QSqlQuery checkQ(QStringLiteral("SELECT COUNT(*) FROM lists;"));
    if (checkQ.next() && checkQ.value(0).toInt() > 0) {
        // Already migrated
        return;
    }

    QFile file(jsonPath);
    if (!file.open(QIODevice::ReadOnly)) {
        return;
    }

    const QJsonDocument doc = QJsonDocument::fromJson(file.readAll());
    file.close();
    const QJsonObject root = doc.object();

    m_db.transaction();

    const QJsonArray listsArray = root.value(QStringLiteral("lists")).toArray();
    for (const auto &val : listsArray) {
        addList(ReminderList::fromJson(val.toObject()));
    }

    const QJsonArray remindersArray = root.value(QStringLiteral("reminders")).toArray();
    for (const auto &val : remindersArray) {
        addReminder(ReminderItem::fromJson(val.toObject()));
    }

    m_db.commit();

    // Rename old json to .bak
    QFile::rename(jsonPath, jsonPath + QStringLiteral(".bak"));
}

QVector<ReminderList> DatabaseManager::getLists()
{
    QVector<ReminderList> lists;
    QSqlQuery q(QStringLiteral("SELECT id, name, color, icon FROM lists ORDER BY position ASC, rowid ASC;"));
    while (q.next()) {
        ReminderList l;
        l.id = q.value(0).toString();
        l.name = q.value(1).toString();
        l.color = q.value(2).toString();
        l.icon = q.value(3).toString();
        lists.append(l);
    }
    return lists;
}

ReminderList DatabaseManager::getList(const QString &listId)
{
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT id, name, color, icon FROM lists WHERE id = ?;"));
    q.addBindValue(listId);
    if (q.exec() && q.next()) {
        ReminderList l;
        l.id = q.value(0).toString();
        l.name = q.value(1).toString();
        l.color = q.value(2).toString();
        l.icon = q.value(3).toString();
        return l;
    }
    return ReminderList{};
}

bool DatabaseManager::addList(const ReminderList &list)
{
    QSqlQuery q;
    q.prepare(QStringLiteral("INSERT OR REPLACE INTO lists (id, name, color, icon) VALUES (?, ?, ?, ?);"));
    q.addBindValue(list.id);
    q.addBindValue(list.name);
    q.addBindValue(list.color);
    q.addBindValue(list.icon);
    return q.exec();
}

bool DatabaseManager::deleteList(const QString &listId)
{
    QSqlQuery q;
    q.prepare(QStringLiteral("DELETE FROM lists WHERE id = ?;"));
    q.addBindValue(listId);
    return q.exec();
}

QVector<ReminderItem> DatabaseManager::getReminders(const QString &filter, const QString &searchQuery)
{
    QVector<ReminderItem> items;
    QString sql = QStringLiteral("SELECT id, list_id, title, notes, due_date, has_due_date, is_completed, is_flagged, priority, created_date, completed_date FROM reminders WHERE 1=1 ");

    const QString todayDateStr = QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));

    if (filter == QStringLiteral("today")) {
        sql += QStringLiteral("AND is_completed = 0 AND has_due_date = 1 AND substr(due_date, 1, 10) <= '") + todayDateStr + QStringLiteral("' ");
    } else if (filter == QStringLiteral("scheduled")) {
        sql += QStringLiteral("AND is_completed = 0 AND has_due_date = 1 ");
    } else if (filter == QStringLiteral("all")) {
        sql += QStringLiteral("AND is_completed = 0 ");
    } else if (filter == QStringLiteral("flagged")) {
        sql += QStringLiteral("AND is_completed = 0 AND is_flagged = 1 ");
    } else if (filter == QStringLiteral("completed")) {
        sql += QStringLiteral("AND is_completed = 1 ");
    } else {
        // Specific List
        sql += QStringLiteral("AND list_id = :list_id ");
    }

    if (!searchQuery.isEmpty()) {
        sql += QStringLiteral("AND (title LIKE :query OR notes LIKE :query) ");
    }

    sql += QStringLiteral("ORDER BY is_completed ASC, has_due_date DESC, due_date ASC, rowid DESC;");

    QSqlQuery q;
    q.prepare(sql);
    if (filter != QStringLiteral("today") && filter != QStringLiteral("scheduled") &&
        filter != QStringLiteral("all") && filter != QStringLiteral("flagged") && filter != QStringLiteral("completed")) {
        q.bindValue(QStringLiteral(":list_id"), filter);
    }
    if (!searchQuery.isEmpty()) {
        const QString wildcard = QStringLiteral("%") + searchQuery + QStringLiteral("%");
        q.bindValue(QStringLiteral(":query"), wildcard);
    }

    if (q.exec()) {
        while (q.next()) {
            ReminderItem item;
            item.id = q.value(0).toString();
            item.listId = q.value(1).toString();
            item.title = q.value(2).toString();
            item.notes = q.value(3).toString();
            item.dueDate = QDateTime::fromString(q.value(4).toString(), Qt::ISODate);
            item.hasDueDate = q.value(5).toBool();
            item.isCompleted = q.value(6).toBool();
            item.isFlagged = q.value(7).toBool();
            item.priority = q.value(8).toInt();
            item.createdDate = QDateTime::fromString(q.value(9).toString(), Qt::ISODate);
            item.completedDate = QDateTime::fromString(q.value(10).toString(), Qt::ISODate);
            items.append(item);
        }
    }

    return items;
}

ReminderItem DatabaseManager::getReminder(const QString &id)
{
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT id, list_id, title, notes, due_date, has_due_date, is_completed, is_flagged, priority, created_date, completed_date FROM reminders WHERE id = ?;"));
    q.addBindValue(id);
    if (q.exec() && q.next()) {
        ReminderItem item;
        item.id = q.value(0).toString();
        item.listId = q.value(1).toString();
        item.title = q.value(2).toString();
        item.notes = q.value(3).toString();
        item.dueDate = QDateTime::fromString(q.value(4).toString(), Qt::ISODate);
        item.hasDueDate = q.value(5).toBool();
        item.isCompleted = q.value(6).toBool();
        item.isFlagged = q.value(7).toBool();
        item.priority = q.value(8).toInt();
        item.createdDate = QDateTime::fromString(q.value(9).toString(), Qt::ISODate);
        item.completedDate = QDateTime::fromString(q.value(10).toString(), Qt::ISODate);
        return item;
    }
    return ReminderItem{};
}

bool DatabaseManager::addReminder(const ReminderItem &item)
{
    QSqlQuery q;
    q.prepare(QStringLiteral(
        "INSERT OR REPLACE INTO reminders (id, list_id, title, notes, due_date, has_due_date, is_completed, is_flagged, priority, created_date, completed_date) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
    ));
    q.addBindValue(item.id);
    q.addBindValue(item.listId);
    q.addBindValue(item.title);
    q.addBindValue(item.notes);
    q.addBindValue(item.dueDate.toString(Qt::ISODate));
    q.addBindValue(item.hasDueDate ? 1 : 0);
    q.addBindValue(item.isCompleted ? 1 : 0);
    q.addBindValue(item.isFlagged ? 1 : 0);
    q.addBindValue(item.priority);
    q.addBindValue(item.createdDate.toString(Qt::ISODate));
    q.addBindValue(item.completedDate.isValid() ? item.completedDate.toString(Qt::ISODate) : QVariant());
    return q.exec();
}

bool DatabaseManager::updateReminder(const ReminderItem &item)
{
    return addReminder(item);
}

bool DatabaseManager::updateReminder(const QString &id, const QString &title, const QString &notes, const QDateTime &dueDate, bool hasDueDate, bool isFlagged, int priority)
{
    QSqlQuery q;
    q.prepare(QStringLiteral(
        "UPDATE reminders SET "
        "  title = ?, "
        "  notes = ?, "
        "  due_date = ?, "
        "  has_due_date = ?, "
        "  is_flagged = ?, "
        "  priority = ? "
        "WHERE id = ?;"
    ));
    q.addBindValue(title);
    q.addBindValue(notes);
    q.addBindValue(dueDate.toString(Qt::ISODate));
    q.addBindValue(hasDueDate ? 1 : 0);
    q.addBindValue(isFlagged ? 1 : 0);
    q.addBindValue(priority);
    q.addBindValue(id);
    return q.exec();
}

bool DatabaseManager::toggleCompleted(const QString &id)
{
    QSqlQuery q;
    q.prepare(QStringLiteral(
        "UPDATE reminders SET "
        "  is_completed = 1 - is_completed, "
        "  completed_date = CASE WHEN is_completed = 0 THEN datetime('now') ELSE NULL END "
        "WHERE id = ?;"
    ));
    q.addBindValue(id);
    return q.exec();
}

bool DatabaseManager::toggleFlagged(const QString &id)
{
    QSqlQuery q;
    q.prepare(QStringLiteral("UPDATE reminders SET is_flagged = 1 - is_flagged WHERE id = ?;"));
    q.addBindValue(id);
    return q.exec();
}

bool DatabaseManager::deleteReminder(const QString &id)
{
    QSqlQuery q;
    q.prepare(QStringLiteral("DELETE FROM reminders WHERE id = ?;"));
    q.addBindValue(id);
    return q.exec();
}

int DatabaseManager::countToday()
{
    const QString todayDateStr = QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));

    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT COUNT(*) FROM reminders WHERE is_completed = 0 AND has_due_date = 1 AND substr(due_date, 1, 10) <= ?;"));
    q.addBindValue(todayDateStr);
    if (q.exec() && q.next()) return q.value(0).toInt();
    return 0;
}

int DatabaseManager::countScheduled()
{
    QSqlQuery q(QStringLiteral("SELECT COUNT(*) FROM reminders WHERE is_completed = 0 AND has_due_date = 1;"));
    if (q.next()) return q.value(0).toInt();
    return 0;
}

int DatabaseManager::countAll()
{
    QSqlQuery q(QStringLiteral("SELECT COUNT(*) FROM reminders WHERE is_completed = 0;"));
    if (q.next()) return q.value(0).toInt();
    return 0;
}

int DatabaseManager::countFlagged()
{
    QSqlQuery q(QStringLiteral("SELECT COUNT(*) FROM reminders WHERE is_completed = 0 AND is_flagged = 1;"));
    if (q.next()) return q.value(0).toInt();
    return 0;
}

int DatabaseManager::countCompleted()
{
    QSqlQuery q(QStringLiteral("SELECT COUNT(*) FROM reminders WHERE is_completed = 1;"));
    if (q.next()) return q.value(0).toInt();
    return 0;
}

int DatabaseManager::countForList(const QString &listId)
{
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT COUNT(*) FROM reminders WHERE is_completed = 0 AND list_id = ?;"));
    q.addBindValue(listId);
    if (q.exec() && q.next()) return q.value(0).toInt();
    return 0;
}

QVector<ReminderItem> DatabaseManager::getDueReminders(const QDateTime &now)
{
    QVector<ReminderItem> due;
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT id, list_id, title, notes FROM reminders WHERE is_completed = 0 AND has_due_date = 1 AND due_date <= ?;"));
    q.addBindValue(now.toString(Qt::ISODate));
    if (q.exec()) {
        while (q.next()) {
            ReminderItem item;
            item.id = q.value(0).toString();
            item.listId = q.value(1).toString();
            item.title = q.value(2).toString();
            item.notes = q.value(3).toString();
            due.append(item);
        }
    }
    return due;
}
