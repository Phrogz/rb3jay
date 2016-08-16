import QtQuick 2.7
import QtQuick.Layouts 1.3

Rectangle {
    id: song
    color: theme.rowBGColor

    property string rating: "zero"
    property alias  title:  songtitle.text
    property alias  artist: songartist.text
    property string album:  "<song album>"
    property int    duration:  215

    signal adjustRating(var song)
    signal hideRating

    RowLayout {
        anchors.fill: parent
        spacing: height*0.05

        Rating {
            width:song.height
            height:song.height
            Layout.preferredWidth:song.height
            Layout.fillHeight:true
        }

        Text {
            id: songtitle
            text: "<song title>"
            font { pixelSize:height * 0.9 }
            elide: Text.ElideMiddle
            maximumLineCount: 1
            verticalAlignment: Text.AlignVCenter
            Layout {
                minimumWidth:song.height;
                preferredWidth:song.height*0.6
                fillWidth:true; fillHeight:true
            }
        }

        Text {
            id: songartist
            text: "<song artist>"
            font: songtitle.font
            elide: Text.ElideMiddle
            maximumLineCount: 1
            verticalAlignment: Text.AlignVCenter
            Layout {
                minimumWidth:song.height;
                preferredWidth:song.height*0.3
                fillWidth:true; fillHeight:true
            }
        }

        Text {
            id: songduration
            text: formatDuration(song.duration)
            font: songtitle.font
            maximumLineCount: 1
            verticalAlignment: Text.AlignVCenter
            horizontalAlignment: Text.AlignRight
            Layout {
                minimumWidth:song.height;
                preferredWidth:song.height*0.3
                fillWidth:true; fillHeight:true
            }
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
