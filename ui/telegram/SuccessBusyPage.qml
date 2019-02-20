import QtQuick 2.6
import Sailfish.Silica 1.0

WizardPageContent {
    id: page
    title: qsTr("Creating account...")
    description: qsTr("Connection succeeded. Saving credentials...")
    canNavigateForward: false

//    onStatusChanged: {
//        if (status == PageStatus.Active) {
//            accountFactory.beginCreation()
//        }
//    }
}
