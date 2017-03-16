project(TelegramAccountSettingsExtension)

set(ProviderName telegram)
set(UI_EXTRA_FILES
    ui/TelegramAddAccount.qml
    ui/TelegramSettingsDisplay.qml
)

cmake_minimum_required(VERSION 2.8)

include(GNUInstallDirs)

set(UI_FILES
    ui/${ProviderName}.qml
    ui/${ProviderName}-settings.qml
    ui/${ProviderName}-update.qml
)

install(
    FILES ${ProviderName}.provider
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/accounts/providers
)

install(
    FILES ${ProviderName}.service
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/accounts/services
)

install(
    FILES ${UI_FILES} ${UI_EXTRA_FILES}
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/accounts/ui
)
