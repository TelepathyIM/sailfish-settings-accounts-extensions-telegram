import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

import TelegramQt 0.2 as Telegram
import Morse 0.1 as Morse

import "telegram"

AccountCreationAgent {
    id: root
    initialPage: Component {
        WizardPage {
            id: wizardPage
            contentSource: Qt.resolvedUrl("telegram/EnterPhone.qml")

            PullDownMenu {
                parent: wizardPage.innerFlickable
                MenuItem {
                    text: qsTr("About")
                    onClicked: {
                        root.showAboutPage()
                    }
                }
                MenuItem {
                    text: qsTr("Settings")
                    onClicked: {
                        root.showNetworkSettings()
                    }
                }
            }
        }
    }

    Connections {
        target: pageStack.currentPage.hasOwnProperty("__wizardPage")
                ? pageStack.currentPage.contentItem
                : pageStack.currentPage
        ignoreUnknownSignals: true
        onSubmitAuthCode: authOperation.submitAuthCode(code)
        onSubmitPassword: authOperation.submitPassword(password)
        onSubmitPhoneNumber: {
            authOperation.startAuthentication()
            authOperation.submitPhoneNumber(phoneNumber)
        }
        onSubmitName: {
            if (authOperation.submitName(firstName, lastName)) {
                root.setActivePage("telegram/EnterCode.qml")
            }
        }

        // Settings page
        onAccountSaveInitiated: {
            root.delayDeletion = true
        }
        onAccountSaveCompleted: {
            root.delayDeletion = false
        }
    }

    property alias phoneNumber: authOperation.phoneNumber
    property int accountId
    property bool accountSettingsRequested: false

    function showNetworkSettings()
    {
        pageStack.push(Qt.resolvedUrl("telegram/NetworkSettingsPage.qml"), {
                           "settingsInstance": networkSettingsWrapper
                       })
    }

    function showAboutPage()
    {
        pageStack.push(Qt.resolvedUrl("telegram/AboutPage.qml"))
    }

    Connections {
        target: pageStack
        onBusyChanged: {
            if (accountSettingsRequested) {
                tryToShowAccountSettings()
            }
        }
    }

    function tryToShowAccountSettings()
    {
        if (pageStack.busy) {
            return
        }
        accountSettingsRequested = false
        pageStack.push(Qt.resolvedUrl("telegram/AccountSettingsPage.qml"), {
                           "accountId": accountId,
                           "context": root,
                       })
    }

    function setActivePage(pageUrl)
    {
        var targetPage = pageStack.currentPage
        if (targetPage.acceptDestinationInstance) {
            targetPage = targetPage.acceptDestinationInstance
        }
        targetPage.context = root
        targetPage.contentSource = Qt.resolvedUrl(pageUrl)
    }

    Client {
        id: telegramClient_
    }

    QtObject {
        id: networkSettingsWrapper

        function getSettings()
        {
            var settingsMap = {}
            var proxySettings = telegramClient_.settings.proxy
            if (proxySettings.address && proxySettings.port) {
                settingsMap["proxy-type"] = "socks5"
                settingsMap["proxy-address"] = proxySettings.address
                settingsMap["proxy-port"] = proxySettings.port
                settingsMap["proxy-username"] = proxySettings.user
                settingsMap["proxy-password"] = proxySettings.password
            }

            if (telegramClient_.hasCustomServer) {
                settingsMap["server-address"] = telegramClient_.customServerAddress
                settingsMap["server-port"] = telegramClient_.customServerPort
                settingsMap["server-key"] = telegramClient_.rsaKeyFileName
            }

            return settingsMap
        }

        function setSettings(settingsMap)
        {
            var proxySettings = telegramClient_.settings.proxy
            if (settingsMap["proxy-type"] === "socks5") {
                proxySettings.address = settingsMap["proxy-address"]
                proxySettings.port = settingsMap["proxy-port"]
                proxySettings.user = settingsMap["proxy-username"] || ""
                proxySettings.password = settingsMap["proxy-password"] || ""
            } else {
                proxySettings.address = ""
                proxySettings.port = 0
                proxySettings.user = ""
                proxySettings.password = ""
            }

            telegramClient_.customServerAddress = settingsMap["server-address"] || ""
            telegramClient_.customServerPort = settingsMap["server-port"] || 0
            telegramClient_.rsaKeyFileName = settingsMap["server-key"] || ""
        }
    }

    Telegram.AuthOperation {
        id: authOperation
        client: telegramClient_
        onCheckInFinished: {
            console.log("check in finished:" + signedIn)
            if (signedIn) {

            } else {
                // TODO: Process network errors
                signIn()
            }
        }

        onStatusChanged: {
            console.log("New status:" + status)
            if (status == Telegram.AuthOperation.SignedIn) {
                console.log("Signed in!")
            }
        }

        onPhoneNumberRequired: {
            root.setActivePage("telegram/EnterPhone.qml")
        }

        onFinished: {
            console.log("Auth operation finished. Succeeded: " + succeeded)
            if (succeeded) {
                root.setActivePage("telegram/SuccessBusyPage.qml")
                accountFactory.beginCreation()
            }
        }

        onFailed: {
            console.log("Auth error:" + JSON.stringify(details))
        }

        onAuthCodeRequired: {
            if (authOperation.registered) {
                root.setActivePage("telegram/EnterCode.qml")
            } else {
                root.setActivePage("telegram/EnterName.qml")
            }
        }

        onPasswordRequired: {
            root.setActivePage("telegram/EnterPassword.qml")
        }
    }

    AccountFactory {
        id: accountFactory
        function beginCreation() {
            var configuration = {}
            configuration["telepathy/account"] = phoneNumber
            configuration["telepathy/param-account"] = phoneNumber

            var proxySettings = telegramClient_.settings.proxy
            if (proxySettings.address && proxySettings.port) {
                configuration["telepathy/param-proxy-type"] = "socks5"
                configuration["telepathy/param-proxy-address"] = proxySettings.address
                configuration["telepathy/param-proxy-port"] = proxySettings.port
                configuration["telepathy/param-proxy-username"] = proxySettings.user
                configuration["telepathy/param-proxy-password"] = proxySettings.password
            }

            if (telegramClient_.hasCustomServer) {
                configuration["telepathy/param-server-address"] = telegramClient_.customServerAddress
                configuration["telepathy/param-server-port"] = telegramClient_.customServerPort

                if (telegramClient_.rsaKeyFileName) {
                    configuration["telepathy/param-server-key"] = telegramClient_.rsaKeyFileName
                }
            }

            configuration["telepathy/param-enable-authentication"] = false

            // Password is not needed for telegram account, but required by the Account library
            var passwordPlaceholder = "password_placeholder"

            console.log("begin creation: " + root.accountProvider.name + " " + root.accountProvider.serviceNames[0])
            console.log("      creation: " + phoneNumber + "|" + passwordPlaceholder)
            console.log("      creation: " + JSON.stringify(configuration, null, 4))

            createAccount(root.accountProvider.name,
                root.accountProvider.serviceNames[0],
                phoneNumber, passwordPlaceholder,
                phoneNumber, // No username // Can be resolved from Telegram
                { "telegram": configuration },       // configuration map
                "Jolla",  // applicationName
                "",       // symmetricKey
                "Jolla")  // credentialsName
        }

        onError: {
            console.log("Telegram account creation error:", message)
            root.accountCreationError(message)
        }

        onSuccess: {
            root.accountId = newAccountId
            root.accountSettingsRequested = true
            root.tryToShowAccountSettings()
            root.accountCreated(newAccountId)
        }
    }
}
