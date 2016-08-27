import QtQuick 2.7
import QtQuick.Controls 2.0

Rectangle {
	id: audiocontrol
    property real volume
    color: ɢtheme.header.backColor

	Slider {
		id: volumeSlider
        anchors.fill: parent
        value: volume/100
	}
}
