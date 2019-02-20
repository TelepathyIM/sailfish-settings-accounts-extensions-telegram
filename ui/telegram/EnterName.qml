import QtQuick 2.6
import Sailfish.Silica 1.0

WizardPageContent {
    id: page
    title: qsTr("Your name")
    description: qsTr("The phone number is not registered. Enter your name to continue.")
    canNavigateForward: firstNameInput.text && lastNameInput.text
    signal submitName(string firstName, string lastName)

    onAccepted: submitName(firstNameInput.text, lastNameInput.text)

    TextField {
        id: firstNameInput
        width: parent.width
        placeholderText: qsTr("First name")
        EnterKey.iconSource: "image://theme/icon-m-enter-next"
        EnterKey.onClicked: lastNameInput.focus = true
    }
    TextField {
        id: lastNameInput
        width: parent.width
        placeholderText: qsTr("Last name")
        EnterKey.iconSource: "image://theme/icon-m-enter-accept"
        EnterKey.onClicked: page.accept()
    }
}
