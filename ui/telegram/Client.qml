import QtQml 2.0

import TelegramQt 0.2 as Telegram
import Morse 0.1 as Morse

Telegram.Client {
    id: root_

    property string version: morseInfo_.version
    property alias phoneNumber: accountStorage_.accountIdentifier
    property alias customServerAddress: customServer_.address
    property alias customServerPort: customServer_.port
    readonly property bool hasCustomServer: customServerAddress && customServerPort
    property alias serverIdentifier: morseInfo_.serverIdentifier
    property alias rsaKeyFileName: rsaKey_.fileName
    property alias accountDataFileName: accountStorage_.fileName

    accountStorage: Telegram.FileAccountStorage {
        id: accountStorage_
        fileName: morseInfo_.accountDataFilePath

        onSynced: console.log("Account synced to " + fileName)
    }

    settings: Telegram.Settings {
        id: telegramSettings_
        pingInterval: 15000
        serverKey: Telegram.RsaKey {
            id: rsaKey_
        }
        serverOptions: hasCustomServer ? [customServer_] : []
    }

    dataStorage: Telegram.InMemoryDataStorage { }

    applicationInformation: Telegram.AppInformation {
        id: appInformation_
        appId: morseInfo_.appId
        appHash: morseInfo_.appHash
        appVersion: morseInfo_.version
        deviceInfo: "pc"
        osInfo: "GNU/Linux"
        languageCode: "en"
    }

    property QtObject morseInfo: Morse.Info {
        id: morseInfo_
        serverIdentifier: hasCustomServer
                          ? root_.customServerAddress + ":" + root_.customServerPort
                          : ""
        accountIdentifier: accountStorage_.accountIdentifier
    }

    readonly property var customServer: Telegram.ServerOption {
        id: customServer_
    }
}
