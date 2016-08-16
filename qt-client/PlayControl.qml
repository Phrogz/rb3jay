import QtQuick 2.7
import QtQuick.Layouts 1.3

RowLayout {
	id: playcontrol
	property bool playingFlag: false
	signal next


    Rectangle { anchors.fill:parent; border{ width:2; color:'red' } }

	Image {
		source: 'qrc:/img/' + (playingFlag?'pause':'play') + '.png'
        sourceSize.height: 100
		clip: true
		fillMode: Image.PreserveAspectFit

		MouseArea {
			anchors.fill: parent
			onClicked: playingFlag = !playingFlag
			// TODO: hoverEnabled:true, highlighting via onEntered/onExited
		}
	}

	Image {
		source: 'qrc:/img/skip.png'
        sourceSize.height: 100
        clip: true
		fillMode: Image.PreserveAspectFit


		MouseArea {
			anchors.fill: parent
			onClicked: playcontrol.next()
			// TODO: hoverEnabled:true, highlighting via onEntered/onExited
		}
	}
}
