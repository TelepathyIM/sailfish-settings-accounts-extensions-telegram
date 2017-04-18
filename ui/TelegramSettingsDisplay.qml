import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

Column {
    id: root

    property bool autoEnableAccount
    property Provider accountProvider
    property int accountId
    property alias acceptableInput: settings.acceptableInput

    property string _defaultServiceName: "telegram"
    property bool _saving

    signal accountSaveCompleted(var success)

    function saveAccount(blockingSave) {
        account.enabled = mainAccountSettings.accountEnabled
        account.displayName = mainAccountSettings.accountDisplayName
        account.enableWithService(_defaultServiceName)

        _saving = true
        if (blockingSave) {
            account.blockingSync()
        } else {
            account.sync()
        }
    }

    function _populateServiceSettings() {
        var serviceSettings = account.configurationValues(_defaultServiceName)
        settings.phoneNumber = serviceSettings["telepathy/account"];

//        settings.username = account.configurationValues("")["default_credentials_username"]
//        if (serviceSettings["telepathy/param-server"])
//            settings.server = serviceSettings["telepathy/param-server"]
//        if (serviceSettings["telepathy/param-ignore-ssl-errors"])
//            settings.ignoreSslErrors = serviceSettings["telepathy/param-ignore-ssl-errors"]
//        if (serviceSettings["telepathy/param-port"])
//            settings.port = serviceSettings["telepathy/param-port"]
//        if (serviceSettings["telepathy/param-priority"])
//            settings.priority = serviceSettings["telepathy/param-priority"]
    }

    width: parent.width
    spacing: Theme.paddingLarge

    AccountMainSettingsDisplay {
        id: mainAccountSettings
        accountProvider: root.accountProvider
        accountUserName: account.defaultCredentialsUserName
        accountDisplayName: account.displayName // "Description"
    }

//    TelegramCommon {
//        id: settings
//        enabled: mainAccountSettings.accountEnabled
//        opacity: enabled ? 1 : 0
//        editMode: true

//        Behavior on opacity { FadeAnimation { } }
//    }

    Column {
        id: settings
        enabled: mainAccountSettings.accountEnabled
        opacity: enabled ? 1 : 0
        width: parent.width
        property alias phoneNumber: phoneNumberEdit.text
        property bool acceptableInput: phoneNumber

        TextField {
            id: phoneNumberEdit
            readOnly: true
            label: "Phone number"
        }

        Behavior on opacity { FadeAnimation { } }
    }

    Account {
        id: account

        identifier: root.accountId
        property bool needToUpdate

        onStatusChanged: {
            if (status === Account.Initialized) {
                mainAccountSettings.accountEnabled = root.autoEnableAccount || account.enabled
                if (root.autoEnableAccount) {
                    enableWithService(_defaultServiceName)
                }
                root._populateServiceSettings()
            } else if (status === Account.Error) {
                // display "error" dialog
            } else if (status === Account.Invalid) {
                // successfully deleted
            }
            if (root._saving && status != Account.SyncInProgress) {
                root._saving = false
                root.accountSaveCompleted(status == Account.Synced)
            }
        }
    }
}
