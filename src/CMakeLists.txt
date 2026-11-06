add_executable(kreminders
    main.cpp
    ReminderItem.h
    DatabaseManager.h
    DatabaseManager.cpp
    RemindersManager.h
    RemindersManager.cpp
    resources.qrc
)

target_link_libraries(kreminders PRIVATE
    Qt6::Core
    Qt6::Gui
    Qt6::Widgets
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::DBus
    Qt6::Sql
    KF6::CoreAddons
    KF6::I18n
    KF6::Notifications
)

install(TARGETS kreminders DESTINATION ${KDE_INSTALL_BINDIR})
install(FILES org.cesar.kreminders.desktop DESTINATION ${KDE_INSTALL_APPDIR})
