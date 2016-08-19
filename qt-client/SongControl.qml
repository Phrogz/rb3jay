import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

Item {
    id: øroot
    property string song
    property string rating: "zero"
    property int    elapsed
    property int    duration
    property real   øspacing: height/20

    Component.onCompleted: console.log('songs are',ørowHeight)

    onSongChanged: {
        console.log('songcontrol song now',song)
    }

    RowLayout {
        anchors.fill:parent
        spacing:øspacing
        ColumnLayout {
            spacing:øspacing
            Text {
                id: songtitle
                Layout.topMargin:øspacing
                Layout.fillWidth:true
                Layout.fillHeight:true
                font { pixelSize:øroot.height/8 }
                text: "<song title>"
                Rectangle{ anchors.fill:parent; color:'transparent'; border{ width:1; color:'green' } }
            }
            Text {
                id: artalb
                property string artist: "<song artist>"
                property string album:  "<song album>"
                Layout.fillWidth:true
                Layout.fillHeight:true
                font: songtitle.font
                text: artist + (album ? ('—'+album) : '')
                Rectangle{ anchors.fill:parent; color:'transparent'; border{ width:1; color:'red' } }
            }
            Slider {
                id: progressSlider
                visible: !!duration
                Layout.fillWidth:true                
                Layout.bottomMargin:øspacing
                Layout.preferredHeight:øroot.height/4
                value: elapsed/duration
                Rectangle{ anchors.fill:parent; color:'transparent'; border{ width:1; color:'blue' } }
            }
        }

        Rating {
            rating: songcontrol.rating
            anchors { right:parent.right; verticalCenter:parent.verticalCenter }
            Layout.preferredWidth:  øroot.height
            Layout.preferredHeight: øroot.height
            Rectangle{ anchors.fill:parent; color:'transparent'; border{ width:1; color:'orange' } }
        }

    }
}
