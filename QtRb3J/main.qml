import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3
import QtWebSockets 1.0

ApplicationWindow {
    id: window
    minimumWidth: 600
    minimumHeight: 300
    visible: true
    width:1280; height:200
    title: "RB3Jay"

    FayeClient {
        id: server
        url: 'http://localhost:8080/faye'
        Component.onCompleted: {
            subscribe('/status',function(s){ console.log(s) });
        }
    }

    Rectangle {
        id: pseudocontent
        height: parent.height - (header.height + footer.height)
        color:'red'
        anchors { top:header.bottom; bottom:footer.top; left:parent.left; right:parent.right }
    }

    header: RowLayout {
        id: header
        spacing: 0
        height: 100
        width: parent.width
        PlayControls {
            Layout.minimumWidth:200
            Layout.maximumWidth:200
            Layout.preferredWidth:200
            Layout.fillHeight:true
        }
        NowPlaying {
            Layout.minimumWidth: 200
            Layout.preferredWidth: parent.width*0.7
            Layout.fillWidth:true
            Layout.fillHeight:true
        }
        AudioControl {
            Layout.minimumWidth: 200
            Layout.preferredWidth: parent.width*0.3
            Layout.fillWidth:true
            Layout.fillHeight:true
        }
    }

    footer: Inspector {
        id: footer
        height:100
    }

}
