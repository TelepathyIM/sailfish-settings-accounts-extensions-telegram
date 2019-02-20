cmake_minimum_required(VERSION 3.1)

project(TelegramAccountSettingsExtension)

set(ProviderName telegram)

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
    FILES ${UI_FILES}
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/accounts/ui
)

install(
    DIRECTORY ui/${ProviderName}
    DESTINATION ${CMAKE_INSTALL_DATAROOTDIR}/accounts/ui
)
