import QtQuick 2.2
import Sailfish.Silica 1.0

ApplicationWindow {
    id: applicationWindow
    objectName: "applicationWindow"
    initialPage: Qt.resolvedUrl("pages/main.qml")
    allowedOrientations: Orientation.All
}
