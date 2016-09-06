import QtQuick 2.7

Image {
	  property QtObject song
	  property string rating: song ? (song.playingNow ? 'active-song' : song.rating) : 'zero'
	  signal show
	  signal hide

	  fillMode: Image.PreserveAspectFit
		source: "qrc:/img/"+rating+".png"
		MouseArea {
			  anchors.fill:parent
				hoverEnabled:true
				onClicked: parent.show()
				onEntered: parent.show()
				onExited:  parent.hide()
		}
}
