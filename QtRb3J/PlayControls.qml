import QtQuick 2.7

Image {
    property bool playing: false
    signal toggle

    fillMode: Image.PreserveAspectFit
    source: 'qrc:/img/' + (playing?'pause':'play') + '.png'

    MouseArea {
        anchors.fill: parent
        onClicked: parent.toggle()
        // TODO: hoverEnabled:true, highlighting via onEntered/onExited
    }
}
