import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

Rectangle {
    id: nowplaying
    property alias title:  songtitle.text
    property string artist: "<song artist>"
    property string album:  "<song album>"
    property string rating: "zero"
    property int elapsed: 0
    property int padding: height/10
    color:'orange'

    ColumnLayout {
        anchors {
            top:parent.top;   topMargin:parent.padding
            left:parent.left; leftMargin:parent.padding
        }
        width: parent.width - 2*parent.padding - rating.width
        height: parent.height - 2*parent.padding

        Text {
            id: songtitle
            Layout.fillWidth:true
            height:parent.height/3
            font { pixelSize:parent.height/3 }
            text: "<song title>"
        }
        Text {
            id: artalb
            Layout.fillWidth:true
            height:parent.height/3
            font: songtitle.font
            text: nowplaying.artist + nowplaying.album ? ('—'+nowplaying.album) : ''
        }
        Slider {
            Layout.fillWidth:true
            height:parent.height/3
        }
    }

    Rating {
        rating: nowplaying.rating
    }
}
