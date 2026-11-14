#include "RemindersManager.h"

#include <KLocalizedString>

#include <QApplication>
#include <QCommandLineParser>
#include <QDir>
#include <QIcon>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQuickStyle>
#include <QQuickWindow>

int main(int argc, char *argv[])
{
    // Force native Wayland backend with real alpha buffer for Liquid Glass blur
    qputenv("QT_QPA_PLATFORM", "wayland;xcb");
    QQuickWindow::setDefaultAlphaBuffer(true);

    if (qEnvironmentVariableIsEmpty("QT_QUICK_CONTROLS_STYLE")) {
        QQuickStyle::setStyle(QStringLiteral("org.kde.desktop"));
    }

    QApplication app(argc, argv);
    KLocalizedString::setApplicationDomain("kreminders");
    app.setApplicationName(QStringLiteral("kreminders"));
    app.setApplicationDisplayName(QStringLiteral("Recordatorios"));
    app.setOrganizationDomain(QStringLiteral("cesar.org"));
    app.setWindowIcon(QIcon::fromTheme(QStringLiteral("org.cesar.kreminders"), QIcon::fromTheme(QStringLiteral("reminders"))));

    QCommandLineParser parser;
    parser.setApplicationDescription(QStringLiteral("Recordatorios — Réplica nativa de Apple Reminders para KDE Plasma 6 en Wayland"));
    parser.addHelpOption();
    parser.addVersionOption();
    parser.process(app);

    auto *manager = new RemindersManager(&app);

    QQmlApplicationEngine engine;
    engine.addImportPath(QDir::homePath() + QStringLiteral("/.local/lib/qt6/qml"));
    engine.addImportPath(QStringLiteral("/home/cesar/Proyectos/cachyos-ui/build/src"));

    engine.rootContext()->setContextProperty(QStringLiteral("remindersManager"), manager);

    const QUrl url(QStringLiteral("qrc:/qml/main.qml"));
    QObject::connect(&engine, &QQmlApplicationEngine::objectCreated,
                     &app, [url](QObject *obj, const QUrl &objUrl) {
        if (!obj && url == objUrl)
            QCoreApplication::exit(-1);
    }, Qt::QueuedConnection);

    engine.load(url);

    return app.exec();
}
