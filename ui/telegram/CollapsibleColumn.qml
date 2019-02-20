import QtQuick 2.6
import Sailfish.Silica 1.0

Column {
    height: enabled ? implicitHeight : 0
    opacity: enabled ? 1.0 : 0.0

    Behavior on height {
        NumberAnimation { duration: 200; easing.type: Easing.InOutQuad }
    }
    Behavior on opacity { FadeAnimator { } }
}
