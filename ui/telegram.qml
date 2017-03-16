import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

AccountCreationAgent {
    id: root

    property Item _settingsDialog

    initialPage: Dialog {
        canAccept: addAccountPage.acceptableInput
        acceptDestination: busyComponent

        SilicaFlickable {
            anchors.fill: parent
            contentHeight: contentColumn.height + Theme.paddingLarge

            Column {
                id: contentColumn
                width: parent.width

                DialogHeader {
                    dialog: initialPage
                }

                Item {
                    x: Theme.horizontalPageMargin
                    width: parent.width - x*2
                    height: icon.height + Theme.paddingLarge

                    Image {
                        id: icon
                        width: Theme.iconSizeLarge
                        height: width
                        anchors.top: parent.top
                        source: root.accountProvider.iconName
                    }
                    Label {
                        anchors {
                            left: icon.right
                            leftMargin: Theme.paddingLarge
                            right: parent.right
                            verticalCenter: icon.verticalCenter
                        }
                        text: root.accountProvider.displayName
                        color: Theme.highlightColor
                        font.pixelSize: Theme.fontSizeLarge
                        truncationMode: TruncationMode.Fade
                    }
                }

                TelegramAddAccount {
                    id: addAccountPage
                }
            }

            VerticalScrollDecorator {}
        }
    }

    Component {
        id: busyComponent
        AccountBusyPage {
            onStatusChanged: {
                if (status == PageStatus.Active) {
                    accountFactory.beginCreation()
                }
            }
        }
    }

    AccountFactory {
        id: accountFactory
        function beginCreation() {
            var configuration = {}
            configuration["telepathy/account"] = addAccountPage.phoneNumber
            configuration["telepathy/keepalive-interval"] = 900
//            if (settings.phoneNumber != "")
//                configuration["telepathy/param-server"] = settings.server
//            if (settings.port != "")
//                configuration["telepathy/param-port"] = settings.port
//            if (settings.ignoreSslErrors)
//                configuration["telepathy/param-ignore-ssl-errors"] = true
//            if (settings.priority != "")
//                configuration["telepathy/param-priority"] = settings.priority

            createAccount(root.accountProvider.name,
                root.accountProvider.serviceNames[0],
                addAccountPage.phoneNumber, "123", // Password is not needed for telegram account, but required by Account library
                "", // No username // Can be resolved from Telegram
                { "telegram": configuration },       // configuration map
                "Jolla",  // applicationName
                "",       // symmetricKey
                "Jolla")  // credentialsName
        }

        onError: {
            console.log("Telegram account creation error:", message)
            initialPage.acceptDestinationInstance.state = "info"
            root.accountCreationError(message)
        }

        onSuccess: {
            root._settingsDialog = settingsComponent.createObject(root, {"accountId": newAccountId})
            pageStack.push(root._settingsDialog)
            root.accountCreated(newAccountId)
        }
    }

    Component {
        id: settingsComponent
        Dialog {
            property alias accountId: settingsDisplay.accountId

            acceptDestination: root.endDestination
            acceptDestinationAction: root.endDestinationAction
            acceptDestinationProperties: root.endDestinationProperties
            acceptDestinationReplaceTarget: root.endDestinationReplaceTarget
            backNavigation: false

            onAccepted: {
                root.delayDeletion = true
                settingsDisplay.saveAccount()
            }

            SilicaFlickable {
                anchors.fill: parent
                contentHeight: header.height + settingsDisplay.height + Theme.paddingLarge

                DialogHeader {
                    id: header
                }

                TelegramSettingsDisplay {
                    id: settingsDisplay
                    anchors.top: header.bottom
                    accountProvider: root.accountProvider
                    autoEnableAccount: true

                    onAccountSaveCompleted: {
                        root.delayDeletion = false
                    }
                }

                VerticalScrollDecorator {}
            }
        }
    }
}
