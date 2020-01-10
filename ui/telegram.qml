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
                           "settingsInstance": telegramSettings
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
                           "settingsInstance": telegramSettings,
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

    Telegram.ServerOption {
        id: customServer
    }

    Telegram.RsaKey {
        id: telegramServerKey
        loadDefault: true
    }

    Telegram.Settings {
        id: telegramSettings
        pingInterval: 15000
        serverKey: telegramServerKey

        function getSettings()
        {
            var settingsMap = {}
            if (proxy.address && proxy.port) {
                settingsMap["proxy-type"] = "socks5"
                settingsMap["proxy-address"] = proxy.address
                settingsMap["proxy-port"] = proxy.port
                settingsMap["proxy-username"] = proxy.user
                settingsMap["proxy-password"] = proxy.password
            }

            console.log("Server options: " + serverOptions.length)
            if (serverOptions.length !== 0) {
                settingsMap["server-address"] = customServer.address
                settingsMap["server-port"] = customServer.port

                if (!telegramServerKey.loadDefault) {
                    settingsMap["server-key"] = telegramServerKey.fileName
                }
            }

            return settingsMap
        }

        function setSettings(settingsMap)
        {
            if (settingsMap["proxy-type"] === "socks5") {
                proxy.address = settingsMap["proxy-address"]
                proxy.port = settingsMap["proxy-port"]
                proxy.user = settingsMap["proxy-username"]
                proxy.password = settingsMap["proxy-password"]
            } else {
                proxy.address = ""
                proxy.port = 0
                proxy.user = ""
                proxy.password = ""
            }

            if (settingsMap["server-address"]) {
                customServer.address = settingsMap["server-address"]
                customServer.port = settingsMap["server-port"]
                serverOptions = [customServer]
            } else {
                serverOptions = []
            }

            if (settingsMap["server-key"]) {
                serverKey.loadDefault = false
                serverKey.fileName = settingsMap["server-key"]
            } else {
                serverKey.fileName = ""
                serverKey.loadDefault = true
            }
        }
    }

    Morse.Info {
        id: morseInfo_
        serverIdentifier: (morseInfo_.serverAddress && morseInfo_.serverPort)
                          ? morseInfo_.serverAddress + ":" + morseInfo_.serverPort
                          : ""
        property string serverAddress: telegramSettings.serverOptions.length
                                       ? customServer.address
                                       : ""
        property int serverPort: telegramSettings.serverOptions.length
                                 ? customServer.port
                                 : 0
    }

    Telegram.FileAccountStorage {
        id: accountStorage

        accountIdentifier: root.phoneNumber
        fileName: morseInfo_.accountDataFilePath

        onSynced: console.log("Account synced to " + fileName)
    }

    Telegram.AppInformation {
        id: appInfo
        appId: morseInfo_.appId
        appHash: morseInfo_.appHash
        appVersion: morseInfo_.version
        deviceInfo: "pc"
        osInfo: "GNU/Linux"
        languageCode: "en"
    }

    Telegram.Client {
        id: telegramClient
        applicationInformation: appInfo
        settings: telegramSettings
        dataStorage: Telegram.InMemoryDataStorage { }
        accountStorage: accountStorage
    }

    Telegram.AuthOperation {
        id: authOperation
        client: telegramClient
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

            if (telegramSettings.proxy.address && telegramSettings.proxy.port) {
                configuration["telepathy/param-proxy-type"] = "socks5"
                configuration["telepathy/param-proxy-address"] = telegramSettings.proxy.address
                configuration["telepathy/param-proxy-port"] = telegramSettings.proxy.port
            }

            if (telegramSettings.serverOptions.length !== 0) {
                configuration["telepathy/param-server-address"] = customServer.address
                configuration["telepathy/param-server-port"] = customServer.port

                if (!telegramServerKey.loadDefault) {
                    configuration["telepathy/param-server-key"] = telegramServerKey.fileName
                }
            }

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
