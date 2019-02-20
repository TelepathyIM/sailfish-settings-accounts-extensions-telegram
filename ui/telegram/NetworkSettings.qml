import QtQuick 2.6
import Sailfish.Silica 1.0
import Sailfish.Pickers 1.0

Column {
    id: content

    spacing: Theme.paddingLarge
    width: parent.width

    property alias customizeServer: customizeServerSwitch.checked
    property alias serverAddress: serverAddressField.text
    property alias serverPort: serverPortField.text
    property alias customizeProxy: customizeProxySwitch.checked
    property alias proxyAddress: proxyAddressField.text
    property alias proxyPort: proxyPortField.text
    property alias serverKeyFile: serverKeyButton.file

    property bool allowChangeServer: false
    readonly property bool hasCustomServer: serverAddress

    readonly property bool acceptableInput: {
        if (customizeProxySwitch.checked) {
            if (!proxyAddress || !proxyPort) {
                return false
            }
        }
        if (customizeServerSwitch.checked) {
            if (!serverAddress || !serverPort) {
                return false
            }
        }

        return true
    }

    SectionHeader {
        id: proxySettings
        text: qsTr("Proxy")
    }

    TextSwitch {
        id: customizeProxySwitch
        checked: false
        text: "Use proxy"
        description: "Use a proxy for this connection"
    }

    CollapsibleColumn {
        width: parent.width
        enabled: customizeProxySwitch.checked

        ComboBox {
            label: qsTr("Type")
            menu: ContextMenu {
                MenuItem {
                    text: qsTr("SOCKS v5")
                }
            }
        }

        TextField {
            id: proxyAddressField
            width: parent.width
            inputMethodHints: Qt.ImhPreferNumbers
            label: qsTr("Address")
            placeholderText: label
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: proxyPortField.focus = true
        }

        TextField {
            id: proxyPortField
            width: parent.width
            inputMethodHints: Qt.ImhDigitsOnly
            label: qsTr("Port number")
            placeholderText: label
            EnterKey.iconSource: "image://theme/icon-m-enter-close"
            validator: IntValidator {
                bottom: 0
                top: 65535
            }
        }
    }

    SectionHeader {
        id: serverSettings
        text: qsTr("Server")
        visible: allowChangeServer || serverAddress
    }

    TextSwitch {
        id: customizeServerSwitch
        checked: false
        text: "Customize server"
        description: "Use a custom server (connect to a custom address of official or unofficial server)"
        visible: allowChangeServer
    }

    CollapsibleColumn {
        width: parent.width
        enabled: customizeServerSwitch.checked || serverAddress

        TextField {
            id: serverAddressField
            width: parent.width
            inputMethodHints: Qt.ImhPreferNumbers
            label: qsTr("Address")
            placeholderText: label
            EnterKey.iconSource: "image://theme/icon-m-enter-next"
            EnterKey.onClicked: serverPortField.focus = true
        }

        TextField {
            id: serverPortField
            width: parent.width
            inputMethodHints: Qt.ImhDigitsOnly
            label: qsTr("Port number")
            placeholderText: label
            EnterKey.iconSource: "image://theme/icon-m-enter-close"
            validator: IntValidator {
                bottom: 0
                top: 65535
            }
        }

        ValueButton {
            id: serverKeyButton
            property string file
            label: qsTr("Server certificate")
            value: file ? qsTr("Custom") : qsTr("Official")

            onClicked: {
                onClicked: pageStack.push(certificatePickerPage)
            }
        }

        Component {
            id: certificatePickerPage
            FilePickerPage {
                onSelectedContentPropertiesChanged: {
                    serverKeyButton.file = selectedContentProperties.filePath
                }
            }
        }
    }
}
