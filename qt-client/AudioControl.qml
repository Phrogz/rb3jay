import QtQuick 2.7
import QtQuick.Controls 1.4

Rectangle {
	id: audiocontrol
	property alias volume: volumeSlider.value
    color: 'blue'

	Slider {
		id: volumeSlider
		anchors.fill: parent
		maximumValue: 100
	}
}
