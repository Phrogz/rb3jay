import QtQuick 2.7
import QtQuick.Layouts 1.3

RowLayout {
	id: playcontrol
	property bool playingFlag: false
	signal togglePlayback
	signal next

	onTogglePlayback: post( playingFlag ? 'paws' : 'play' )

	Image {
		source: 'qrc:/img/' + (playingFlag?'pause':'play') + '.png'
		Layout.preferredWidth:  playcontrol.height
		Layout.preferredHeight: playcontrol.height
		clip:true; fillMode:Image.PreserveAspectFit

		MouseArea {
			anchors.fill: parent
			onClicked: playcontrol.togglePlayback()
			// TODO: hoverEnabled:true, highlighting via onEntered/onExited
		}
	}

	Image {
		source: 'qrc:/img/skip.png'
		Layout.preferredWidth:  playcontrol.height
		Layout.preferredHeight: playcontrol.height
		clip:true; fillMode:Image.PreserveAspectFit

		MouseArea {
			anchors.fill: parent
			onClicked: playcontrol.next()
			// TODO: hoverEnabled:true, highlighting via onEntered/onExited
		}
	}
}
