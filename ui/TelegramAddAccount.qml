import QtQuick 2.2
import Sailfish.Silica 1.0
import com.jolla.settings.accounts 1.0

import TelegramQt 1.0

Column {
    id: telegramCommonColumn
    property bool editMode: true
    property alias phoneNumber: phoneNumberField.text
    property bool acceptableInput: secretHelper.credentialDataExists
    property bool showDetails: telegramCore.connected || secretHelper.credentialDataExists

    width: parent.width

    AccountSecretHelper {
        id: secretHelper
        secretDirectory: "/home/nemo/.cache/telepathy-morse/secrets"
        phoneNumber: phoneNumberField.text
        format: AccountSecretHelper.FormatBinary
    }

    AppInformation {
        id: appInfo
        appId: 14617
        appHash: "e17ac360fd072f83d5d08db45ce9a121" // Telepathy-Morse app hash
        appVersion: "0.1"
        deviceInfo: "pc"
        osInfo: "GNU/Linux"
        languageCode: "en"
    }

    TelegramCore {
        id: telegramCore
        updatesEnabled: false
        applicationInformation: appInfo
        property bool connected: connectionState >= TelegramNamespace.ConnectionStateConnected
        property bool phoneNumberNeeded: needsState === needsPhoneNumber
        property bool authCodeNeeded: needsState === needsAuthCode
        property bool passwordNeeded: needsState === needsPassword
        property bool busy: pendingPhoneNumberForCheck

        property int needsState: needsPhoneNumber
        readonly property int needsNothing: 0
        readonly property int needsPhoneNumber: 1
        readonly property int needsAuthCode: 2
        readonly property int needsPassword: 3
        readonly property bool hasValidCredentials: connectionState >= TelegramNamespace.ConnectionStateAuthenticated

        property string pendingPhoneNumberForCheck

        property string currentPhone: telegramCommonColumn.phoneNumber

        onCurrentPhoneChanged: currentPhoneRegistrationKnown = false

        property bool currentPhoneRegistrationKnown: false
        property bool currentPhoneRegistered: false

        function checkPhone(phone)
        {
            pendingPhoneNumberForCheck = phone
            if (!connected) {
                debugDataModel.addMessage("requestPhoneStatus: " + phone + " (pending)")
                tryToConnect()
                return
            }

            debugDataModel.addMessage("requestPhoneStatus: " + phone)
            requestPhoneStatus(phone)
        }

        onConnectedChanged: {
            if (connected) {
                if (pendingPhoneNumberForCheck) {
                    debugDataModel.addMessage("Connected. Request status of " + pendingPhoneNumberForCheck)
                    requestPhoneStatus(pendingPhoneNumberForCheck)
                }
            }
        }

        onPhoneStatusReceived: {
            debugDataModel.addMessage("phoneStatusReceived: " + phone + " registered: " + registered)

            if (phone != pendingPhoneNumberForCheck) {
                debugDataModel.addMessage("Got statues of different phone, than requested: " + phone + " vs " + pendingPhoneNumberForCheck)
            }
            pendingPhoneNumberForCheck = ""
            if (phone == currentPhone) {
                currentPhoneRegistrationKnown = true
                currentPhoneRegistered = registered
            }
        }

        function tryToConnect() {
            if (connectionState !== TelegramNamespace.ConnectionStateDisconnected) {
                debugDataModel.addMessage("Asked to connect, but the state is " + connectionState + " already")
                return
            }

            debugDataModel.addMessage("Init connection...")
            telegramCore.initConnection()
        }

        function requestAuthCode(phone) {
            debugDataModel.addMessage("Request auth code for phone number " + phone)
            telegramCore.requestPhoneCode(phone)
        }

        function trySignIn(phone, code) {
            debugDataModel.addMessage("Sign in account " + phone + " with code " + code)
            needsState = needsNothing
            signIn(phone, code)
        }

        function tryPassword2(password) {
            debugDataModel.addMessage("Try pass")
            needsState = needsNothing
            tryPassword(password)
        }

        onPhoneCodeRequired: {
            debugDataModel.addMessage("Phone code required")
            needsState = needsAuthCode
        }

        onConnectionStateChanged: {
            debugDataModel.addMessage("Connection state changed to " + state)

//            if (state === TelegramNamespace.ConnectionStateAuthRequired) {
//                debugDataModel.addMessage("requestPhoneCode " + phoneNumberField.text)
//                telegramCore.requestPhoneCode(phoneNumberField.text)
//                needsState = needsAuthCode
//            }

            if (state === TelegramNamespace.ConnectionStateAuthenticated) {
                debugDataModel.addMessage("Authenticated and ready!")
                needsState = needsNothing
            }
        }

        onAuthSignErrorReceived: {
            debugDataModel.addMessage("AuthSignErrorReceived: " + errorMessage + " (code: " + errorCode + ")")
            if (errorCode == TelegramNamespace.AuthSignErrorPhoneCodeIsInvalid) {
                debugDataModel.addMessage("Phone code is not valid")
                needsState = needsAuthCode
            }
        }

        onAuthorizationErrorReceived: {
            debugDataModel.addMessage("AuthorizationErrorReceived: " + errorMessage + " (code: " + errorCode + ")")
            if (errorCode === TelegramNamespace.UnauthorizedSessionPasswordNeeded) {
                needsState = needsPassword

                passwordField.focus = true
                telegramCore.getPassword()
            }
        }

        onPasswordInfoReceived: {
            debugDataModel.addMessage("onPasswordInfoReceived")
        }

        onLoggedOut: {
            debugDataModel.addMessage("Log out result: " + result)
        }
    }

    TextField {
        id: phoneNumberField
        readOnly: !editMode
        width: parent.width
        enabled: telegramCore.phoneNumberNeeded
        inputMethodHints: Qt.ImhDigitsOnly
        errorHighlight: !text
        placeholderText: qsTr("Enter phone number")
        label: qsTr("Phone number")
        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
        EnterKey.onClicked: {
            telegramCore.checkPhone(text)
        }
    }

    Column {
        anchors.horizontalCenter: parent.horizontalCenter
        Button {
            id: checkPhoneButton
            visible: phoneNumberField.text
            enabled: pendingPhoneNumberForCheck === ""
            text: qsTr("Continue")
            onClicked: {
                telegramCore.checkPhone(phoneNumberField.text)
                enabled = false
            }
        }
        Item {
            id: checkPhoneButtonSpacer
            visible: !checkPhoneButton.visible
            width: 1
            height: checkPhoneButton.height
        }
        Item {
            id: checkPhoneButtonPadding
            width: 1
            height: Theme.paddingSmall
        }
    }

    Column {
        id: detailsItem
        visible: telegramCommonColumn.showDetails
        width: parent.width

        Row {
            x: Theme.horizontalPageMargin
            spacing: Theme.paddingSmall
            height: phoneCodeBusyIndicator.height + Theme.paddingSmall
            Label {
                id: phoneStatusTextLabel
                text: qsTr("Phone status:")
                anchors.verticalCenter: parent.verticalCenter
            }
            BusyIndicator {
                id: phoneCodeBusyIndicator
                size: BusyIndicatorSize.ExtraSmall
                running: telegramCore.pendingPhoneNumberForCheck
                visible: running
                anchors.verticalCenter: phoneStatusTextLabel.verticalCenter
            }
            Label {
                id: phoneStatusLabel
                visible: !telegramCore.pendingPhoneNumberForCheck
                text: telegramCore.currentPhoneRegistrationKnown ?
                          (telegramCore.currentPhoneRegistered ? qsTr("Registered") : qsTr("Not registered"))
                        : qsTr("Unknown")
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        Column {
            visible: telegramCore.currentPhoneRegistrationKnown
            width: parent.width

            Button {
                text: telegramCore.currentPhoneRegistered ? qsTr("Sign in") : qsTr("Sign up")
                onClicked: {
                    telegramCore.requestAuthCode(telegramCommonColumn.phoneNumber)
                }
                anchors.horizontalCenter: parent.horizontalCenter
            }

            TextField {
                id: authCodeField
                width: parent.width
                enabled: telegramCore.authCodeNeeded
                onEnabledChanged: {
                    if (enabled) {
                        focus = true
                    }
                }
                errorHighlight: telegramCore.authCodeNeeded && !text
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhSensitiveData | Qt.ImhDigitsOnly
                echoMode: TextInput.Password
                label: qsTr("Auth code")
                placeholderText: telegramCore.authCodeNeeded ? label : "Auth code is not required (yet)"
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: {
                    telegramCore.trySignIn(phoneNumberField.text, authCodeField.text)
                }
            }

            TextField {
                id: passwordField
                width: parent.width
                enabled: telegramCore.passwordNeeded
                onEnabledChanged: {
                    if (enabled) {
                        focus = true
                    }
                }
                errorHighlight: telegramCore.passwordNeeded && !text
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase | Qt.ImhSensitiveData
                echoMode: TextInput.Password
                label: qsTr("Password")
                placeholderText: telegramCore.passwordNeeded ? label : qsTr("Password is not required (yet)")
                EnterKey.iconSource: "image://theme/icon-m-enter-accept"
                EnterKey.onClicked: {
                    telegramCore.tryPassword2(text)
                }
            }
        }

        SectionHeader {
            text: qsTr("Credentials data")
        }

        Label {
            x: Theme.horizontalPageMargin
            width: parent.width - Theme.horizontalPageMargin * 2
            wrapMode: Text.Wrap
            font.pixelSize: Theme.fontSizeMedium
            color: Theme.highlightColor
            text: secretHelper.credentialDataExists ? "Credentials data already exists" : "Sign in and dump credentials data to create account"
        }

        Row {
            spacing: Theme.paddingLarge
            anchors.horizontalCenter: parent.horizontalCenter
            Button {
                enabled: telegramCore.hasValidCredentials
                text: qsTr("Dump the data")
                onClicked: {
                    if(secretHelper.saveCredentialsData(telegramCore.connectionSecretData)) {
                        debugDataModel.addMessage("Credentials data saved")
                    } else {
                        debugDataModel.addMessage("Unable to save credentials data")
                    }
                }
            }
            Button {
                text: qsTr("Wipe exists data")
                enabled: secretHelper.credentialDataExists
                onClicked: {
                    if(secretHelper.removeCredentialsData()) {
                        debugDataModel.addMessage("Credentials data removed")
                    } else {
                        debugDataModel.addMessage("Unable to remove credentials data")
                    }
                }
            }
        }

        ListModel {
            id: debugDataModel
            function addMessage(message)
            {
                console.log(message)
                append({"timestamp": Qt.formatDateTime(new Date(), "hh:mm:ss"), "message": message })
            }
        }

        TextSwitch {
            id: debugViewSwitch
            text: qsTr("Show debug data")
            description: "Check this to view logs"
        }

        Repeater {
            id: logRepeater
            model: debugViewSwitch.checked ? debugDataModel : 0
            Row {
                spacing: Theme.paddingSmall
                Label {
                    text: model.timestamp
                }
                Label {
                    text: model.message
                    wrapMode: Text.Wrap
                    width: telegramCommonColumn.width - x
                }
            }
        }
        Label {
            visible: debugViewSwitch.checked && (logRepeater.count === 0)
            text: qsTr("There is no log messages yet")
        }
    }
}
