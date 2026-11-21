#include "DatabaseManager.h"

#include <QDir>
#include <QFile>
#include <QJsonArray>
#include <QJsonDocument>
#include <QJsonObject>
#include <QSet>
#include <QSqlQuery>
#include <QSqlError>
#include <QStandardPaths>
#include <QVariant>
#include <QtLogging>

namespace {
struct FilterClause {
    QString sql;
    QVariantList bindValues;
};

FilterClause buildFilterClause(const QString &filter, bool completedOnly, bool includeCompleted)
{
    FilterClause clause;
    const QString todayDateStr = QDate::currentDate().toString(QStringLiteral("yyyy-MM-dd"));

    if (filter == QStringLiteral("completed")) {
        clause.sql += QStringLiteral("AND is_completed = 1 ");
        return clause;
    }

    if (completedOnly) {
        clause.sql += QStringLiteral("AND is_completed = 1 ");
    } else if (!includeCompleted) {
        clause.sql += QStringLiteral("AND is_completed = 0 ");
    }

    if (filter == QStringLiteral("today")) {
        clause.sql += QStringLiteral("AND has_due_date = 1 AND substr(due_date, 1, 10) <= ? ");
        clause.bindValues.append(todayDateStr);
    } else if (filter == QStringLiteral("scheduled")) {
        clause.sql += QStringLiteral("AND has_due_date = 1 ");
    } else if (filter == QStringLiteral("all")) {
        // No extra filter beyond completion state
    } else if (filter == QStringLiteral("flagged")) {
        clause.sql += QStringLiteral("AND is_flagged = 1 ");
    } else if (filter == QStringLiteral("urgent")) {
        clause.sql += QStringLiteral("AND (is_urgent = 1 OR priority = 3) ");
    } else if (filter == QStringLiteral("tags_all")) {
        clause.sql += QStringLiteral("AND length(trim(COALESCE(tags, ''))) > 0 ");
    } else if (filter.startsWith(QStringLiteral("tag:"))) {
        const QString tag = filter.mid(4).trimmed();
        clause.sql += QStringLiteral("AND (' ' || COALESCE(tags, '') || ' ') LIKE ? ");
        clause.bindValues.append(QString(QStringLiteral("% ") + tag + QStringLiteral(" %")));
    } else {
        clause.sql += QStringLiteral("AND list_id = ? ");
        clause.bindValues.append(filter);
    }

    return clause;
}

ReminderItem readReminderRow(const QSqlQuery &q)
{
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
    item.isUrgent = q.value(11).toBool();
    item.tags = q.value(12).toString();
    item.hasDueTime = q.value(13).isNull() ? true : q.value(13).toBool();
    item.hasLocation = q.value(14).toBool();
    item.whenMessaging = q.value(15).toBool();
    return item;
}
}

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
        "  completed_date TEXT,"
        "  is_urgent INTEGER DEFAULT 0,"
        "  tags TEXT DEFAULT '',"
        "  has_due_time INTEGER DEFAULT 1,"
        "  has_location INTEGER DEFAULT 0,"
        "  when_messaging INTEGER DEFAULT 0"
        ");"
    ));

    // Safe schema migration for existing SQLite databases
    QSet<QString> existingColumns;
    if (q.exec(QStringLiteral("PRAGMA table_info(reminders);"))) {
        while (q.next()) {
            existingColumns.insert(q.value(1).toString());
        }
    }
    if (!existingColumns.contains(QStringLiteral("is_urgent"))) {
        q.exec(QStringLiteral("ALTER TABLE reminders ADD COLUMN is_urgent INTEGER DEFAULT 0;"));
    }
    if (!existingColumns.contains(QStringLiteral("tags"))) {
        q.exec(QStringLiteral("ALTER TABLE reminders ADD COLUMN tags TEXT DEFAULT '';"));
    }
    if (!existingColumns.contains(QStringLiteral("has_due_time"))) {
        q.exec(QStringLiteral("ALTER TABLE reminders ADD COLUMN has_due_time INTEGER DEFAULT 1;"));
    }
    if (!existingColumns.contains(QStringLiteral("has_location"))) {
        q.exec(QStringLiteral("ALTER TABLE reminders ADD COLUMN has_location INTEGER DEFAULT 0;"));
    }
    if (!existingColumns.contains(QStringLiteral("when_messaging"))) {
        q.exec(QStringLiteral("ALTER TABLE reminders ADD COLUMN when_messaging INTEGER DEFAULT 0;"));
    }

    // Create Indices
    q.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS idx_reminders_list ON reminders(list_id);"));
    q.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS idx_reminders_due ON reminders(has_due_date, is_completed, due_date);"));
    q.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS idx_reminders_flagged ON reminders(is_flagged, is_completed);"));
    q.exec(QStringLiteral("CREATE INDEX IF NOT EXISTS idx_reminders_urgent ON reminders(is_urgent, is_completed);"));
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

QVector<ReminderItem> DatabaseManager::getReminders(const QString &filter, const QString &searchQuery, bool includeCompleted, const QString &sortBy)
{
    QVector<ReminderItem> items;
    QString sql = QStringLiteral(
        "SELECT id, list_id, title, notes, due_date, has_due_date, is_completed, is_flagged, priority, "
        "created_date, completed_date, is_urgent, tags, has_due_time, has_location, when_messaging "
        "FROM reminders WHERE 1=1 "
    );

    const FilterClause clause = buildFilterClause(filter, false, includeCompleted);
    sql += clause.sql;

    if (!searchQuery.isEmpty()) {
        sql += QStringLiteral("AND (title LIKE ? OR notes LIKE ? OR tags LIKE ?) ");
    }

    if (sortBy == QStringLiteral("creationDate")) {
        sql += QStringLiteral("ORDER BY is_completed ASC, created_date DESC, rowid DESC;");
    } else if (sortBy == QStringLiteral("priority")) {
        sql += QStringLiteral("ORDER BY is_completed ASC, priority DESC, is_urgent DESC, has_due_date DESC, due_date ASC;");
    } else if (sortBy == QStringLiteral("title")) {
        sql += QStringLiteral("ORDER BY is_completed ASC, title COLLATE NOCASE ASC;");
    } else {
        sql += QStringLiteral("ORDER BY is_completed ASC, has_due_date DESC, due_date ASC, rowid DESC;");
    }

    QSqlQuery q;
    q.prepare(sql);
    for (const QVariant &val : clause.bindValues) {
        q.addBindValue(val);
    }
    if (!searchQuery.isEmpty()) {
        const QString wildcard = QStringLiteral("%") + searchQuery + QStringLiteral("%");
        q.addBindValue(wildcard);
        q.addBindValue(wildcard);
        q.addBindValue(wildcard);
    }

    if (q.exec()) {
        while (q.next()) {
            items.append(readReminderRow(q));
        }
    }

    return items;
}

ReminderItem DatabaseManager::getReminder(const QString &id)
{
    QSqlQuery q;
    q.prepare(QStringLiteral(
        "SELECT id, list_id, title, notes, due_date, has_due_date, is_completed, is_flagged, priority, "
        "created_date, completed_date, is_urgent, tags, has_due_time, has_location, when_messaging "
        "FROM reminders WHERE id = ?;"
    ));
    q.addBindValue(id);
    if (q.exec() && q.next()) {
        return readReminderRow(q);
    }
    return ReminderItem{};
}

bool DatabaseManager::addReminder(const ReminderItem &item)
{
    QSqlQuery q;
    q.prepare(QStringLiteral(
        "INSERT OR REPLACE INTO reminders "
        "(id, list_id, title, notes, due_date, has_due_date, is_completed, is_flagged, priority, "
        "created_date, completed_date, is_urgent, tags, has_due_time, has_location, when_messaging) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);"
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
    q.addBindValue(item.isUrgent ? 1 : 0);
    q.addBindValue(item.tags);
    q.addBindValue(item.hasDueTime ? 1 : 0);
    q.addBindValue(item.hasLocation ? 1 : 0);
    q.addBindValue(item.whenMessaging ? 1 : 0);
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

bool DatabaseManager::updateReminderFull(const QString &id, const QString &listId, const QString &title, const QString &notes, const QDateTime &dueDate, bool hasDueDate, bool isFlagged, bool isUrgent, int priority, const QString &tags, bool hasDueTime, bool hasLocation, bool whenMessaging)
{
    QSqlQuery q;
    q.prepare(QStringLiteral(
        "UPDATE reminders SET "
        "  list_id = ?, "
        "  title = ?, "
        "  notes = ?, "
        "  due_date = ?, "
        "  has_due_date = ?, "
        "  is_flagged = ?, "
        "  is_urgent = ?, "
        "  priority = ?, "
        "  tags = ?, "
        "  has_due_time = ?, "
        "  has_location = ?, "
        "  when_messaging = ? "
        "WHERE id = ?;"
    ));
    q.addBindValue(listId);
    q.addBindValue(title);
    q.addBindValue(notes);
    q.addBindValue(dueDate.toString(Qt::ISODate));
    q.addBindValue(hasDueDate ? 1 : 0);
    q.addBindValue(isFlagged ? 1 : 0);
    q.addBindValue(isUrgent ? 1 : 0);
    q.addBindValue(priority);
    q.addBindValue(tags);
    q.addBindValue(hasDueTime ? 1 : 0);
    q.addBindValue(hasLocation ? 1 : 0);
    q.addBindValue(whenMessaging ? 1 : 0);
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

bool DatabaseManager::toggleUrgent(const QString &id)
{
    QSqlQuery q;
    q.prepare(QStringLiteral("UPDATE reminders SET is_urgent = 1 - is_urgent WHERE id = ?;"));
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

bool DatabaseManager::clearCompletedForFilter(const QString &filter)
{
    const FilterClause clause = buildFilterClause(filter, true, true);
    QSqlQuery q;
    q.prepare(QStringLiteral("DELETE FROM reminders WHERE 1=1 ") + clause.sql + QStringLiteral(";"));
    for (const QVariant &val : clause.bindValues) {
        q.addBindValue(val);
    }
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

int DatabaseManager::countUrgent()
{
    QSqlQuery q(QStringLiteral("SELECT COUNT(*) FROM reminders WHERE is_completed = 0 AND (is_urgent = 1 OR priority = 3);"));
    if (q.next()) return q.value(0).toInt();
    return 0;
}

int DatabaseManager::countCompleted()
{
    QSqlQuery q(QStringLiteral("SELECT COUNT(*) FROM reminders WHERE is_completed = 1;"));
    if (q.next()) return q.value(0).toInt();
    return 0;
}

int DatabaseManager::countCompletedForFilter(const QString &filter)
{
    const FilterClause clause = buildFilterClause(filter, true, true);
    QSqlQuery q;
    q.prepare(QStringLiteral("SELECT COUNT(*) FROM reminders WHERE 1=1 ") + clause.sql + QStringLiteral(";"));
    for (const QVariant &val : clause.bindValues) {
        q.addBindValue(val);
    }
    if (q.exec() && q.next()) return q.value(0).toInt();
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

QStringList DatabaseManager::getAllTags()
{
    QStringList tags;
    QSet<QString> seen;
    QSqlQuery q(QStringLiteral("SELECT tags FROM reminders WHERE is_completed = 0 AND length(trim(COALESCE(tags, ''))) > 0;"));
    while (q.next()) {
        const QStringList tokens = q.value(0).toString().split(QLatin1Char(' '), Qt::SkipEmptyParts);
        for (QString tok : tokens) {
            if (!tok.startsWith(QLatin1Char('#'))) {
                tok.prepend(QLatin1Char('#'));
            }
            if (!seen.contains(tok)) {
                seen.insert(tok);
                tags.append(tok);
            }
        }
    }
    return tags;
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
