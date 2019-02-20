import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

import TelegramQt 0.2 as Telegram

Dialog {
    id: newAccountSettingsDialog
    property alias accountId: settingsDisplay.accountId

    property var context

    property var settingsInstance

    acceptDestination: context.endDestination
    acceptDestinationAction: context.endDestinationAction
    acceptDestinationProperties: context.endDestinationProperties
    acceptDestinationReplaceTarget: context.endDestinationReplaceTarget
    backNavigation: false

    signal accountSaveInitiated()
    signal accountSaveCompleted(var success)

    onAccepted: settingsDisplay.saveAccount()

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: header.height + settingsDisplay.height + Theme.paddingLarge
        onContentHeightChanged: verticalScroll.showDecorator()

        DialogHeader {
            id: header
        }

        AccountSettings {
            id: settingsDisplay
            anchors.top: header.bottom
            accountProvider: context.accountProvider
            width: parent.width
            autoEnableAccount: true

            onAccountSaveCompleted: {
                newAccountSettingsDialog.accountSaveCompleted(success)
            }
            onAccountSaveInitiated: {
                newAccountSettingsDialog.accountSaveInitiated()
            }
        }

        VerticalScrollDecorator {
            id: verticalScroll
        }
    }
}
