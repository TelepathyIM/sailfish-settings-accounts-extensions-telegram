import QtQuick 2.6
import Sailfish.Silica 1.0

WizardPageContent {
    id: page
    title: qsTr("Your phone")
    description: qsTr("Please confirm your country code and enter your phone number.")
    canNavigateForward: phoneNumberField.acceptableInput
    onAccepted: submitPhoneNumber(countryBox.code + phoneNumberField.text)
    signal submitPhoneNumber(string phoneNumber)

    ComboBox {
        id: countryBox
        menu: ContextMenu {
            Repeater {
                model: phoneCodeModel
                MenuItem {
                    text: phoneCodeModel.get(index).country
                }
            }
        }
        label: qsTr("Country")

        readonly property string code: phoneCodeModel.get(currentIndex).code
        readonly property var length: phoneCodeModel.get(currentIndex).length
    }

    Item {
        id: row
        x: Theme.horizontalPageMargin
        height: phoneNumberField.implicitHeight
        width: parent.width - x

        Label {
            id: phoneCode
            y: phoneNumberField.textTopMargin
            text: "+" + countryBox.code
        }

        TextField {
            id: phoneNumberField
            textLeftMargin: Theme.paddingMedium
            anchors.left: phoneCode.right
            anchors.right: parent.right
            inputMethodHints: Qt.ImhDigitsOnly
            maximumLength: countryBox.length
            validator: RegExpValidator { regExp: /\d{5,15}/ }
            label: qsTr("Phone number")
            placeholderText: label
            placeholderColor: Theme.highlightColor
            color: Theme.highlightColor
            EnterKey.iconSource: "image://theme/icon-m-enter-accept"
            EnterKey.onClicked: page.accept()
        }
    }

    ListModel {
        id: phoneCodeModel
        ListElement {
            code: "44"
            country: "United Kingdom"
            length: 10
        }
        ListElement {
            code: "7"
            country: "Russian Federation"
            length: 10
        }
        ListElement {
            code: "34"
            country: "Spain"
            length: 9 // 6 or 7, followed by 8 digits
        }
        ListElement {
            code: ""
            country: "Custom"
            length: 12
        }
    }
}
