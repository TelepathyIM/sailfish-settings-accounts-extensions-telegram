import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

Dialog {
    property var settingsInstance

    Component.onCompleted: {
        var settingsMap = settingsInstance.getSettings()
        console.log("Loaded: " + JSON.stringify(settingsMap))

        if (settingsMap["proxy-type"] === "socks5") {
            networkSettings.customizeProxy = true
            networkSettings.proxyAddress = settingsMap["proxy-address"]
            networkSettings.proxyPort = settingsMap["proxy-port"]
            networkSettings.proxyUsername = settingsMap["proxy-username"]
            networkSettings.proxyPassword = settingsMap["proxy-password"]
        }

        if (settingsMap["server-address"]) {
            networkSettings.customizeServer = true
            networkSettings.serverAddress = settingsMap["server-address"]
            networkSettings.serverPort = settingsMap["server-port"]
            networkSettings.serverKeyFile = settingsMap["server-key"];
        }
    }

    onAccepted: {
        var settingsMap = {}
        if (networkSettings.customizeProxy) {
            settingsMap["proxy-type"] = "socks5"
            settingsMap["proxy-address"] = networkSettings.proxyAddress
            settingsMap["proxy-port"] = networkSettings.proxyPort
            settingsMap["proxy-username"] = networkSettings.proxyUsername
            settingsMap["proxy-password"] = networkSettings.proxyPassword
        }

        if (networkSettings.hasCustomServer) {
            settingsMap["server-address"] = networkSettings.serverAddress
            settingsMap["server-port"] = networkSettings.serverPort
            if (networkSettings.serverKeyFile) {
                settingsMap["server-key"] = networkSettings.serverKeyFile
            }
        }

        console.log("Accepted: " + JSON.stringify(settingsMap))
        settingsInstance.setSettings(settingsMap)
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: contentColumn.height + Theme.paddingLarge

        onContentHeightChanged: verticalScroll.showDecorator()

        VerticalScrollDecorator {
            id: verticalScroll
        }

        Column {
            id: contentColumn

            spacing: Theme.paddingLarge
            width: parent.width

            DialogHeader {
                id: pageHeader
                title: qsTr("Network settings")
            }

            NetworkSettings {
                id: networkSettings
                allowChangeServer: true
            }
        }
    }
}
