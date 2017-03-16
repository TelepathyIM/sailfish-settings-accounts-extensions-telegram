import QtQuick 2.0
import Sailfish.Silica 1.0
import Sailfish.Accounts 1.0
import com.jolla.settings.accounts 1.0

AccountCredentialsAgent {
    id: root

    canCancelUpdate: true

    initialPage: Dialog {
        id: updateDialog

        acceptDestinationAction: PageStackAction.Push // has to be, so this page continues to live, so it can call _updateCredentials() AFTER accepted()
        acceptDestination: AccountBusyPage { // intermediate page - to handle success/errors
            busyDescription: updatingAccountText
        }

        property bool _updateAccepted
        property bool _checkMandatoryFields
        property bool _passwordEdited
        property string _defaultServiceName: "jabber"
        property string _oldUsername: account.defaultCredentialsUserName

        function _updateCredentials() {
            var password = ""
            if (_passwordEdited) {
                password = passwordField.text
                _passwordEdited = false
            }
            if (account.hasSignInCredentials("Jolla", "Jolla")) {
                account.updateSignInCredentials("Jolla", "Jolla",
                                                account.signInParameters(_defaultServiceName, usernameField.text, passwordField.text))
            } else {
                // build account configuration map, to avoid another asynchronous state round trip.
                var configValues = { "": account.configurationValues("") }
                var serviceNames = account.supportedServiceNames
                for (var si in serviceNames) {
                    configValues[serviceNames[si]] = account.configurationValues(serviceNames[si])
                }
                accountFactory.recreateAccountCredentials(account.identifier, _defaultServiceName,
                                                          usernameField.text, passwordField.text,
                                                          account.signInParameters(_defaultServiceName, usernameField.text, passwordField.text),
                                                          "Jolla", "", "Jolla", configValues)
            }
        }

        canAccept: passwordField.text.length > 0 && usernameField.text.length > 0

        onAcceptPendingChanged: {
            if (acceptPending === true) {
                _checkMandatoryFields = true
            }
        }

        onStatusChanged: {
            // we don't do this in onAccepted(), otherwise the _updateCredentials()
            // operation might complete before the page transition is completed,
            // in which case the attempt to then transition to the final destination
            // would fail.  So, we wait until the initial transition is complete, first.
            if (status == PageStatus.Inactive && result == DialogResult.Accepted) {
                _updateCredentials()
            }
        }

        onRejected: {
            if(account.status === Account.SigningIn) {
                account.cancelSignInOperation()
            }
        }

        DialogHeader {
            id: pageHeader
        }

        Column {
            anchors.top: pageHeader.bottom
            spacing: Theme.paddingLarge
            width: parent.width

            Label {
                //TODO: change to proper id once translations can be integrated again
                text: qsTrId("accounts-me-update_credentials")
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeExtraLarge
                x: Theme.horizontalPageMargin
                width: parent.width - x*2
                color: Theme.highlightColor
            }

            TextField {
                id: usernameField
                width: parent.width
                inputMethodHints: Qt.ImhNoPredictiveText | Qt.ImhNoAutoUppercase
                errorHighlight: !text && updateDialog._checkMandatoryFields

                //: Placeholder text for XMPP username
                //% "Enter username"
                placeholderText: qsTrId("components_accounts-ph-jabber_username_placeholder")
                //: XMPP username
                //% "Username"
                label: qsTrId("components_accounts-la-jabber_username")
                text: updateDialog._oldUsername
                onTextChanged: {
                    if (focus) {
                        // Updating username also updates password; clear it if it's default value
                        if (!updateDialog._passwordEdited)
                            passwordField.text = ""
                    }
                }
                EnterKey.iconSource: "image://theme/icon-m-enter-next"
                EnterKey.onClicked: passwordField.focus = true
            }


            PasswordField {
                id: passwordField
                errorHighlight: !text && updateDialog._checkMandatoryFields
                text: "default" // we can't read the password
                onTextChanged: {
                    if (focus) {
                        updateDialog._passwordEdited = true
                    }
                }
                EnterKey.iconSource: "image://theme/icon-m-enter-close"
                EnterKey.onClicked: root.focus = true
            }
        }
    }

    Account {
        id: account
        identifier: root.accountId

        onSignInCredentialsUpdated: {
            root.credentialsUpdated(identifier)
            root.goToEndDestination()
        }

        onSignInError: {
            root.credentialsUpdateError(errorMessage)
            var busyPage = updateDialog.acceptDestination
            busyPage.state = 'info'
            busyPage.infoHeading = busyPage.errorHeadingText
            busyPage.infoDescription = busyPage.accountUpdateErrorText
        }
    }
}

