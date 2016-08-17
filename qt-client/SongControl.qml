import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

Item {
    id: øroot
    property string song
    property string rating: "zero"
    property int    elapsed
    property int    duration
    property int    øpadding: height/10

    onSongChanged: {
        console.log('songcontrol song now',song)
    }

    ColumnLayout {
        anchors {
            top:parent.top;   topMargin:øpadding 
            left:parent.left; leftMargin:øpadding
        }
        width:  parent.width  - 2*øpadding - rating.width
        height: parent.height - 2*øpadding

        Text {
            id: songtitle
            Layout.fillWidth:true
            Layout.preferredHeight: øroot.height/3
            font { pixelSize:øroot.height/3 }
            text: "<song title>"
        }
        Text {
            id: artalb
            property string artist: "<song artist>"
            property string album:  "<song album>"
            Layout.fillWidth:true
            Layout.preferredHeight: øroot.height/3
            font: songtitle.font
            text: artist + (album ? ('—'+album) : '')
        }
        Slider {
            id: progressSlider
            visible: !!duration
            Layout.fillWidth:true
            Layout.preferredHeight: øroot.height/3
            value: elapsed/duration
        }
    }

    Rating {
        rating: songcontrol.rating
        anchors { right:parent.right; verticalCenter:parent.verticalCenter }
    }
}
