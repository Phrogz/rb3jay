import QtQuick 2.7
import QtQuick.Controls 2.0
import QtQuick.Layouts 1.3

Rectangle {
	id: øroot
	color: ɢtheme.details.backColor
	property QtObject song: ɢsongdb.songPlaying
	property int  elapsed
	property int  duration
	property real øspacing: height/20

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
				font: ɢtheme.details.titleFont
				text: song ? (song.title || song.file) : ''
				leftPadding:øspacing
			}
			Text {
				id: artalb
				Layout.fillWidth:true
				Layout.fillHeight:true
				verticalAlignment: Text.AlignVCenter
				font: ɢtheme.details.artalbFont
				text: song ? (song.artist||'') + (song.album ? (' (on <i>'+song.album+'</i>)') : '') : ''
				leftPadding:øspacing
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
			song: song
			Layout.rightMargin:     øroot.height * 0.1
			Layout.preferredWidth:  øroot.height * 0.8
			Layout.preferredHeight: øroot.height * 0.8
		}
	}
}
