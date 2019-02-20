import QtQuick 2.6
import Sailfish.Silica 1.0

Dialog {
    id: pageLoader

    property string title: (contentLoader.status === Loader.Ready) ? contentLoader.item.title : qsTr("Loading...")
    property string description: (contentLoader.status === Loader.Ready) ? contentLoader.item.description : ""

    acceptDestination: (contentLoader.status === Loader.Ready) ? contentLoader.item.acceptDestination : null
    canNavigateForward: (contentLoader.status === Loader.Ready) ? contentLoader.item.canNavigateForward : false

    property alias contentSource: contentLoader.source
    property alias contentItem: contentLoader.item

    onAccepted: {
        contentLoader.item.accepted()
    }

    property alias innerFlickable: flickable

    readonly property alias __wizardPage: pageLoader.objectName

    property var context

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: contentColumn.height + Theme.paddingLarge

        VerticalScrollDecorator {}

        Column {
            id: contentColumn

            spacing: Theme.paddingLarge
            width: parent.width

            DialogHeader {
                id: pageHeader
                title: pageLoader.title
            }

            Label {
                id: descriptionText
                x: Theme.horizontalPageMargin
                width: parent.width - 2 * x
                text: pageLoader.description
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                visible: text
            }

            Loader {
                id: contentLoader
                source: pageLoader.contentSource
                width: parent.width

                property alias context: pageLoader.context
            }

            Connections {
                target: contentLoader.item
                onAccept: pageLoader.accept()
            }
        }
    }

    BusyIndicator {
        id: busyIndicator
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
        visible: contentLoader.status !== Loader.Ready
        running: visible
    }
}
