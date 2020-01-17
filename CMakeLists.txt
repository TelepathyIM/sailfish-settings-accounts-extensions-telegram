cmake_minimum_required(VERSION 3.1)

project(TelegramAccountSettingsExtension)

set(ProviderName telegram)

include(GNUInstallDirs)

set(UI_FILES
    ui/telegram.qml
    ui/telegram-settings.qml
    ui/telegram-update.qml
)

set(UI_EXTRA_FILES
    ui/telegram/AboutPage.qml
    ui/telegram/AccountSettings.qml
    ui/telegram/AccountSettingsPage.qml
    ui/telegram/Client.qml
    ui/telegram/CollapsibleColumn.qml
    ui/telegram/EnterCode.qml
    ui/telegram/EnterName.qml
    ui/telegram/EnterPassword.qml
    ui/telegram/EnterPhone.qml
    ui/telegram/NetworkSettings.qml
    ui/telegram/NetworkSettingsPage.qml
    ui/telegram/SuccessBusyPage.qml
    ui/telegram/WizardPage.qml
    ui/telegram/WizardPageContent.qml
)

source_group("Extra files"
    FILES ${UI_EXTRA_FILES}
)

source_group("Service files"
    FILES
        ${ProviderName}.provider
        ${ProviderName}.service
)

add_custom_target(${ProviderName}-files
    SOURCES
        ${UI_FILES}
        ${UI_EXTRA_FILES}
        ${ProviderName}.provider
        ${ProviderName}.service
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
