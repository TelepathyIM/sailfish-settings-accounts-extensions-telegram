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

    property alias settings: settings_

    signal accountLoaded()
    signal accountSaveInitiated()
    signal accountSaveCompleted(var success)

    AccountMainSettingsDisplay {
        id: mainAccountSettings
        accountProvider: root.accountProvider
        accountUserName: account.defaultCredentialsUserName
        accountDisplayName: account.displayName // "Description"
    }

    Column {
        id: settings_
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
                root.accountLoaded()
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

        account.setConfigurationValue("", "default_credentials_username", settings_.phoneNumber)
        // param-account is required by Telepathy; it's generated from credentials on creation, but
        // needs to be updated manually
        account.setConfigurationValue(serviceName, "telepathy/param-account", settings_.phoneNumber)

        if (settings_.serverAddress) {
            account.setConfigurationValue(serviceName, "telepathy/param-server-address", settings_.serverAddress)
            account.setConfigurationValue(serviceName, "telepathy/param-server-port", settings_.serverPort)

            if (settings_.serverKeyFile) {
                account.setConfigurationValue(serviceName, "telepathy/param-server-key", settings_.serverKeyFile)
            } else {
                account.removeConfigurationValue(serviceName, "telepathy/param-server-key")
            }
        } else {
            account.removeConfigurationValue(serviceName, "telepathy/param-server-address")
            account.removeConfigurationValue(serviceName, "telepathy/param-server-port")
            account.removeConfigurationValue(serviceName, "telepathy/param-server-key")
        }

        if (settings_.proxyAddress && settings_.proxyPort) {
            account.setConfigurationValue(serviceName, "telepathy/param-proxy-type", "socks5")
            account.setConfigurationValue(serviceName, "telepathy/param-proxy-address", settings_.proxyAddress)
            account.setConfigurationValue(serviceName, "telepathy/param-proxy-port", settings_.proxyPort)

            if (settings_.proxyUsername) {
                account.setConfigurationValue(serviceName, "telepathy/param-proxy-username", settings_.proxyUsername)
                account.setConfigurationValue(serviceName, "telepathy/param-proxy-password", settings_.proxyPassword)
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

        settings_.phoneNumber = account.configurationValues("")["default_credentials_username"]

        if (serviceSettings["telepathy/param-server-address"]) {
            settings_.serverAddress = serviceSettings["telepathy/param-server-address"]
            settings_.serverPort = serviceSettings["telepathy/param-server-port"]

            if (serviceSettings["telepathy/param-server-key"]) {
                settings_.serverKeyFile = serviceSettings["telepathy/param-server-key"]
            }
        }
        if (serviceSettings["telepathy/param-proxy-address"]) {
            settings_.customizeProxy = true
            settings_.proxyAddress = serviceSettings["telepathy/param-proxy-address"]
            settings_.proxyPort = serviceSettings["telepathy/param-proxy-port"]
            settings_.proxyUsername = serviceSettings["telepathy/param-proxy-username"] || ""
            settings_.proxyPassword = serviceSettings["telepathy/param-proxy-password"] || ""
        } else {
            settings_.customizeProxy = false
        }
    }
}
