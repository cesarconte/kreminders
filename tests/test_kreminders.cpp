/*
 * SPDX-FileCopyrightText: 2026 Cesar
 * SPDX-FileCopyrightText: 2026 CachyOS UI contributors
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

#include "RemindersManager.h"

#include <QCoreApplication>
#include <QDir>
#include <QFile>
#include <QQmlComponent>
#include <QQmlContext>
#include <QQmlEngine>
#include <QStandardPaths>
#include <QTest>

class TestKReminders : public QObject
{
    Q_OBJECT

private Q_SLOTS:
    void initTestCase()
    {
        // Set temp database path and offscreen QPA for automated tests
        qputenv("QT_QPA_PLATFORM", "offscreen");
        QStandardPaths::setTestModeEnabled(true);
        const QString testDataDir = QStandardPaths::writableLocation(QStandardPaths::AppDataLocation);
        QDir(testDataDir).removeRecursively();
    }

    void testRemindersManagerBasicOps()
    {
        RemindersManager manager;

        const int initialAll = manager.allCount();
        const int initialToday = manager.todayCount();

        // 1. Add reminder for today
        manager.addReminder(QStringLiteral("Comprar café"),
                            QStringLiteral("Grano arábica"),
                            QDateTime::currentDateTime(),
                            true,
                            false,
                            1);

        QCOMPARE(manager.allCount(), initialAll + 1);
        QCOMPARE(manager.todayCount(), initialToday + 1);

        // 2. Add flagged reminder
        manager.addReminder(QStringLiteral("Reunión urgente"),
                            QStringLiteral("Sala de juntas"),
                            QDateTime::currentDateTime().addDays(1),
                            true,
                            true,
                            2);

        QVERIFY(manager.flaggedCount() >= 1);

        // 3. Test Smart List Selection
        manager.selectSmartList(QStringLiteral("today"));
        QCOMPARE(manager.currentFilter(), QStringLiteral("today"));
        QCOMPARE(manager.currentTitle(), QStringLiteral("Hoy"));

        manager.selectSmartList(QStringLiteral("scheduled"));
        QCOMPARE(manager.currentFilter(), QStringLiteral("scheduled"));
        QCOMPARE(manager.currentTitle(), QStringLiteral("Programados"));

        manager.selectSmartList(QStringLiteral("flagged"));
        QCOMPARE(manager.currentFilter(), QStringLiteral("flagged"));
        QCOMPARE(manager.currentTitle(), QStringLiteral("Con marca"));

        manager.selectSmartList(QStringLiteral("urgent"));
        QCOMPARE(manager.currentFilter(), QStringLiteral("urgent"));
        QCOMPARE(manager.currentTitle(), QStringLiteral("Urgentes"));

        // 4. Test Urgent, Tags & Update Details
        manager.addReminder(QStringLiteral("Graphite"),
                            QStringLiteral(""),
                            QDateTime(),
                            false,
                            false,
                            0);
        const auto idx = manager.tasksModel()->index(0, 0);
        const QString createdId = manager.tasksModel()->data(idx, TasksModel::IdRole).toString();
        QVERIFY(!createdId.isEmpty());

        manager.updateReminderDetails(createdId,
                                      QStringLiteral("default"),
                                      QStringLiteral("Graphite"),
                                      QStringLiteral("Color iMac"),
                                      QDateTime(),
                                      false,
                                      true,
                                      true,
                                      3,
                                      QStringLiteral("Not-orange"));
        QVERIFY(manager.urgentCount() >= 1);
        QVERIFY(manager.allTags().contains(QStringLiteral("#Not-orange")));

        // 5. Test Add Custom List
        manager.addList(QStringLiteral("Trabajo"), QStringLiteral("#FF9500"), QStringLiteral("briefcase"));
        QVERIFY(manager.listsModel() != nullptr);
    }

    void testQmlSyntaxAndCachyWindow()
    {
        QQmlEngine engine;
        engine.addImportPath(QStringLiteral("/usr/lib/qt6/qml"));

        auto *manager = new RemindersManager(&engine);
        engine.rootContext()->setContextProperty(QStringLiteral("remindersManager"), manager);

        const QString mainQml = QStringLiteral(KREMINDERS_SOURCE_DIR) + QStringLiteral("/src/qml/main.qml");
        QVERIFY2(QFile::exists(mainQml), "main.qml does not exist");

        QQmlComponent component(&engine, QUrl::fromLocalFile(mainQml));
        if (!component.isReady()) {
            qWarning() << "QML Component Errors:" << component.errors();
        }
        QVERIFY(component.isReady());

        QObject *rootObj = component.create();
        QVERIFY(rootObj != nullptr);
        delete rootObj;
    }
};

QTEST_MAIN(TestKReminders)
#include "test_kreminders.moc"
