TEMPLATE = aux

account_ui.files = \
    ui/telegram-settings.qml \
    ui/telegram-update.qml \
    ui/telegram.qml \
    ui/telegram/*

account_ui.path = /usr/share/accounts/ui

provider.files = telegram.provider
provider.path = /usr/share/accounts/providers
service.files = telegram.service
service.path = /usr/share//accounts/services

INSTALLS += account_ui provider service
OTHER_FILES += rpm/*
