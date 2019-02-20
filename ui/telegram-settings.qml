import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

import "telegram" as Internal

AccountSettingsAgent {
    id: root

    initialPage: Page {
        onPageContainerChanged: {
            if (pageContainer == null) {
                settingsDisplay.saveAccount()
            }
        }

        Component.onDestruction: {
            if (status == PageStatus.Active && !credentialsUpdater.running) {
                // app closed while settings are open, so save settings synchronously
                settingsDisplay.saveAccount(true)
            }
        }

        SilicaFlickable {
            anchors.fill: parent
            contentHeight: header.height + settingsDisplay.height + Theme.paddingLarge

            StandardAccountSettingsPullDownMenu {
                onCredentialsUpdateRequested: {
                    credentialsUpdater.replaceWithCredentialsUpdatePage(root.accountId)
                }
                allowSync: false
                onAccountDeletionRequested: {
                    root.accountDeletionRequested()
                    pageStack.pop()
                }
            }

            PageHeader {
                id: header
                title: root.accountsHeaderText
            }

            Internal.AccountSettings {
                id: settingsDisplay
                anchors.top: header.bottom
                accountProvider: root.accountProvider
                accountId: root.accountId

                onAccountSaveInitiated: {
                    root.delayDeletion = true
                }
                onAccountSaveCompleted: {
                    root.delayDeletion = false
                }
            }

            onContentHeightChanged: verticalScroll.showDecorator()

            VerticalScrollDecorator {
                id: verticalScroll
            }
        }

        AccountCredentialsUpdater {
            id: credentialsUpdater
        }
    }
}
