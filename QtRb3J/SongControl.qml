import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

Rectangle {
    id: songcontrol
    property string song
    property string rating: "zero"
    property int    elapsed
    property int    duration
    property int    _padding: height/10

    onSongChanged: {
        console.log('songcontrol song now',song)
    }

    ColumnLayout {
        anchors {
            top:parent.top;   topMargin:_padding 
            left:parent.left; leftMargin:_padding
        }
        width:  parent.width  - 2*_padding - rating.width
        height: parent.height - 2*_padding

        Text {
            id: songtitle
            Layout.fillWidth:true
            height:parent.height/3
            font { pixelSize:parent.height/3 }
            text: "<song title>"
        }
        Text {
            id: artalb
            property string artist: "<song artist>"
            property string album:  "<song album>"
            Layout.fillWidth:true
            height:parent.height/3
            font: songtitle.font
            text: artist + album ? ('—'+album) : ''
        }
        Slider {
            id: progressSlider
            visible: !!duration
            Layout.fillWidth:true
            height:parent.height/3
            value: elapsed/duration
        }
    }

    Rating {
        rating: songcontrol.rating
    }
}
