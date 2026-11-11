find_package(Qt6Test ${QT_MIN_VERSION} REQUIRED)

add_executable(test_kreminders test_kreminders.cpp)
target_compile_definitions(test_kreminders PRIVATE KREMINDERS_SOURCE_DIR="${CMAKE_SOURCE_DIR}")
target_link_libraries(test_kreminders PRIVATE
    kreminders_core
    Qt6::Core
    Qt6::Qml
    Qt6::Test
)

add_test(NAME test_kreminders COMMAND test_kreminders)
