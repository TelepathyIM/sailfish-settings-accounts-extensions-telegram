import QtQuick 2.0
import Sailfish.Silica 1.0

import Morse 0.1 as Morse
import TelegramQt 0.2 as Telegram

Page {
    id: page_

    Morse.Info {
        id: morseInfo_
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: contentColumn.height

        VerticalScrollDecorator { }

        Column {
            id: contentColumn

            spacing: Theme.paddingLarge
            width: parent.width

            PageHeader { title: qsTr("About") }

            DetailItem {
                label: "Morse version"
                value: morseInfo_.version
            }
            DetailItem {
                label: "Morse build"
                value: morseInfo_.buildVersion
            }
            DetailItem {
                label: "TelegramQt version"
                value: Telegram.Namespace.version
            }
            DetailItem {
                label: "TelegramQt build"
                value: Telegram.Namespace.buildVersion
            }
        }
    }
}
