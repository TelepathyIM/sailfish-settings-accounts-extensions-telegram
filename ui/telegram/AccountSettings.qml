import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

import TelegramQt 0.2 as Telegram

Column {
    id: root

    width: parent.width
    spacing: Theme.paddingLarge

    property Provider accountProvider
    property int accountId
    property bool autoEnableAccount: false

    property string serviceName: "telegram"
    property bool _saving

    signal accountSaveInitiated()
    signal accountSaveCompleted(var success)

    AccountMainSettingsDisplay {
        id: mainAccountSettings
        accountProvider: root.accountProvider
        accountUserName: account.defaultCredentialsUserName
        accountDisplayName: account.displayName // "Description"
    }

    Column {
        id: settings
        enabled: mainAccountSettings.accountEnabled
        opacity: enabled ? 1 : 0
        width: parent.width
        property alias phoneNumber: phoneNumberEdit.text
        property alias serverAddress: networkSettings.serverAddress
        property alias serverPort: networkSettings.serverPort
        property alias serverKeyFile: networkSettings.serverKeyFile
        property alias customizeProxy: networkSettings.customizeProxy
        property alias proxyAddress: networkSettings.proxyAddress
        property alias proxyPort: networkSettings.proxyPort
        property alias proxyUsername: networkSettings.proxyUsername
        property alias proxyPassword: networkSettings.proxyPassword
        property bool acceptableInput: phoneNumber && networkSettings.acceptableInput

        Behavior on opacity { FadeAnimation { } }

        SectionHeader {
            id: accountSettings
            text: qsTr("Account")
        }

        TextField {
            id: phoneNumberEdit
            width: parent.width
            readOnly: true
            label: qsTr("Phone number")
        }

        /* Not supported yet
        TextField {
            id: firstNameEdit
            width: parent.width
            readOnly: true
            label: qsTr("First name")
        }

        TextField {
            id: lastNameEdit
            width: parent.width
            readOnly: true
            label: qsTr("Last name")
        }
        */

        NetworkSettings {
            id: networkSettings
        }
    }

    Account {
        id: account

        identifier: root.accountId
        property bool needToUpdate

        onStatusChanged: {
            if (status === Account.Initialized) {
                mainAccountSettings.accountEnabled = autoEnableAccount || account.enabled
                console.log("Enable: " + autoEnableAccount)
                if (autoEnableAccount) {
                    console.log("Enable with service " + serviceName)
                    enableWithService(serviceName)
                }
                populateSettingsUi()
            } else if (status === Account.Error) {
                // display "error" dialog
            } else if (status === Account.Invalid) {
                // successfully deleted
            }
            if (_saving && status != Account.SyncInProgress) {
                _saving = false
                root.accountSaveCompleted(status == Account.Synced)
                console.log("save complete!")
            }
        }
    }

    function saveAccount(blockingSave) {
        console.log("Save account")
        accountSaveInitiated()

        account.enabled = mainAccountSettings.accountEnabled
        account.displayName = mainAccountSettings.accountDisplayName
        account.enableWithService(serviceName)

        account.setConfigurationValue("", "default_credentials_username", settings.phoneNumber)
        // param-account is required by Telepathy; it's generated from credentials on creation, but
        // needs to be updated manually
        account.setConfigurationValue(serviceName, "telepathy/param-account", settings.phoneNumber)

        if (settings.serverAddress) {
            account.setConfigurationValue(serviceName, "telepathy/param-server-address", settings.serverAddress)
            account.setConfigurationValue(serviceName, "telepathy/param-server-port", settings.serverPort)

            if (settings.serverKeyFile) {
                account.setConfigurationValue(serviceName, "telepathy/param-server-key", settings.serverKeyFile)
            } else {
                account.removeConfigurationValue(serviceName, "telepathy/param-server-key")
            }
        } else {
            account.removeConfigurationValue(serviceName, "telepathy/param-server-address")
            account.removeConfigurationValue(serviceName, "telepathy/param-server-port")
            account.removeConfigurationValue(serviceName, "telepathy/param-server-key")
        }

        if (settings.proxyAddress && settings.proxyPort) {
            account.setConfigurationValue(serviceName, "telepathy/param-proxy-type", "socks5")
            account.setConfigurationValue(serviceName, "telepathy/param-proxy-address", settings.proxyAddress)
            account.setConfigurationValue(serviceName, "telepathy/param-proxy-port", settings.proxyPort)

            if (settings.proxyUsername) {
                account.setConfigurationValue(serviceName, "telepathy/param-proxy-username", settings.proxyUsername)
                account.setConfigurationValue(serviceName, "telepathy/param-proxy-password", settings.proxyPassword)
            } else {
                account.removeConfigurationValue(serviceName, "telepathy/param-proxy-username")
                account.removeConfigurationValue(serviceName, "telepathy/param-proxy-password")
            }
        } else {
            account.removeConfigurationValue(serviceName, "telepathy/param-proxy-type")
            account.removeConfigurationValue(serviceName, "telepathy/param-proxy-address")
            account.removeConfigurationValue(serviceName, "telepathy/param-proxy-port")
            account.removeConfigurationValue(serviceName, "telepathy/param-proxy-username")
            account.removeConfigurationValue(serviceName, "telepathy/param-proxy-password")
        }

        _saving = true
        if (blockingSave) {
            account.blockingSync()
        } else {
            account.sync()
        }

        // accountSaveCompleted() emitted on account state changed
    }

    function populateSettingsUi() {
        var serviceSettings = account.configurationValues(serviceName)

        settings.phoneNumber = account.configurationValues("")["default_credentials_username"]

        if (serviceSettings["telepathy/param-server-address"]) {
            settings.serverAddress = serviceSettings["telepathy/param-server-address"]
            settings.serverPort = serviceSettings["telepathy/param-server-port"]

            if (serviceSettings["telepathy/param-server-key"]) {
                settings.serverKeyFile = serviceSettings["telepathy/param-server-key"]
            }
        }
        if (serviceSettings["telepathy/param-proxy-address"]) {
            settings.customizeProxy = true
            settings.proxyAddress = serviceSettings["telepathy/param-proxy-address"]
            settings.proxyPort = serviceSettings["telepathy/param-proxy-port"]
            settings.proxyUsername = serviceSettings["telepathy/param-proxy-username"]
            settings.proxyPassword = serviceSettings["telepathy/param-proxy-password"]
        } else {
            settings.customizeProxy = false
        }
    }
}
