import QtQuick 2.7
import QtQuick.Layouts 1.3

Rectangle {
    id: øroot
    color: ɢtheme.songBGColor

    property QtObject song

    signal adjustRating(var song)
    signal hideRating

    RowLayout {
        anchors.fill: parent
        spacing: height*0.05

        Rating {
            song: song
            Layout.preferredWidth: øroot.height
            Layout.preferredHeight:øroot.height
        }

        Text {
            text: song && song.title || '-'
            font: ɢtheme.songFont
            elide: Text.ElideRight
            maximumLineCount: 1
            verticalAlignment: Text.AlignVCenter
            Layout.minimumWidth:  øroot.height
            Layout.preferredWidth:øroot.width*0.6
            Layout.fillWidth: true
            Layout.fillHeight:true
        }

        Text {
            text: song && song.artist || '-'
            font: ɢtheme.songFont
            elide: Text.ElideMiddle
            maximumLineCount: 1
            verticalAlignment: Text.AlignVCenter
            Layout.minimumWidth:  øroot.height
            Layout.preferredWidth:øroot.width*0.3
            Layout.fillWidth: true
            Layout.fillHeight:true
        }

        Text {
            text: formatDuration(song && song.duration)
            font: ɢtheme.songFont
            maximumLineCount: 1
            verticalAlignment:   Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            Layout.minimumWidth:  øroot.height
            Layout.preferredWidth:øroot.width*0.1
            Layout.fillWidth: true
            Layout.fillHeight:true

            function formatDuration(seconds){
                if (isNaN(seconds)) return '-';
                var hors = Math.floor(seconds/3600);
                var mins = Math.floor(seconds/60%60);
                seconds  = Math.round(seconds%60);
                if (seconds<10) seconds = "0"+seconds;
                if (hors) return hors+":"+(mins<10?'0':'')+mins+":"+seconds;
                else      return mins+":"+seconds;
            }
        }
    }
}
