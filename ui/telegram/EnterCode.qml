import QtQuick 2.6
import Sailfish.Silica 1.0

WizardPageContent {
    id: page
    title: qsTr("Your code")
    description: qsTr("We have sent an SMS with an activation code to your phone +" + context.phoneNumber)
    canNavigateForward: authCodeField.acceptableInput
    signal submitAuthCode(string code)

    onAccepted: submitAuthCode(authCodeField.text)

    TextField {
        id: authCodeField
        width: parent.width
        inputMethodHints: Qt.ImhDigitsOnly
        maximumLength: 5
        validator: RegExpValidator { regExp: /\d{5}/ }
        label: qsTr("Auth code")
        placeholderText: qsTr("Enter the code")
        placeholderColor: Theme.highlightColor
        color: Theme.highlightColor
        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
        EnterKey.onClicked: page.accept()
    }
}
