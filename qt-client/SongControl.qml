import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

Rectangle {
    id: øroot
    color: ɢtheme.detailsBGColor
    property string song
    property string rating: "zero"
    property int    elapsed
    property int    duration
    property real   øspacing: height/20

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
                verticalAlignment: Text.AlignVCenter
                font: ɢtheme.headerTitleFont
                text: "<song title>"
            }
            Text {
                id: artalb
                property string artist: "<song artist>"
                property string album:  "<song album>"
                Layout.fillWidth:true
                Layout.fillHeight:true
                verticalAlignment: Text.AlignVCenter
                font: ɢtheme.headerArtAlbFont
                text: artist + (album ? ('—'+album) : '')
            }
            Slider {
                id: progressSlider
                opacity: duration ? 1 : 0
                Layout.fillWidth:true                
                Layout.bottomMargin:øspacing
                Layout.preferredHeight:øroot.height/4
                value: elapsed/duration
            }
        }

        Rating {
            rating: songcontrol.rating
            Layout.rightMargin:     øroot.height * 0.1
            Layout.preferredWidth:  øroot.height * 0.8
            Layout.preferredHeight: øroot.height * 0.8
        }
    }
}
