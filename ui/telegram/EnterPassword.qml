import QtQuick 2.6
import Sailfish.Silica 1.0

WizardPageContent {
    id: page
    title: qsTr("Password")
    description: qsTr("You have enabled Two-Step Verification, so your account is protected with an additional password.")
    canNavigateForward: passwordField.text
    signal submitPassword(string password)

    onAccepted: submitPassword(passwordField.text)

    PasswordField {
        id: passwordField
        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
        EnterKey.onClicked: page.accept()
    }
}
