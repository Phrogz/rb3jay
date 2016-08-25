import QtQuick 2.7
import QtQuick.Controls 2.0

Rectangle {
	id: audiocontrol
	property alias volume: volumeSlider.value
	  color: ɢtheme.header.backColor

	Slider {
		id: volumeSlider
		    anchors.fill: parent
	}
}
