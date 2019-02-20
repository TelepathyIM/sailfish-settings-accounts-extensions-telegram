import QtQuick 2.0
import Sailfish.Silica 1.0

Column {
    id: page

    property bool canNavigateForward: false
    property string title
    property string description

    property var acceptDestination: Qt.resolvedUrl("WizardPage.qml")

    signal accept()
    signal accepted()
}
