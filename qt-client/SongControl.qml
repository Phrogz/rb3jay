import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3

Rectangle {
	id: root
	color: ɢtheme.details.backColor
	property QtObject song: ɢsongdb.songPlaying
	property int  elapsed
	property int  duration
	property real øspacing: height/10

	RowLayout {
		anchors.fill:parent
		spacing:øspacing
		ColumnLayout {
			spacing:øspacing
			Text {
				Layout.topMargin:øspacing
				Layout.fillWidth:true
				Layout.fillHeight:true
				verticalAlignment: Text.AlignVCenter
				font: ɢtheme.details.titleFont
				text: song ? (song.title || song.file) : ''
				leftPadding:øspacing
				elide: Text.ElideRight
			}
			Text {
				Layout.fillWidth:true
				Layout.fillHeight:true
				verticalAlignment: Text.AlignVCenter
				font: ɢtheme.details.artalbFont
				text: song ? (song.artist||'') + (song.album ? (' (on <i>'+song.album+'</i>)') : '') : ''
				leftPadding:øspacing
				elide: Text.ElideRight
			}
			RowLayout {
				opacity:duration ? 1 : 0
				spacing:øspacing
				Layout.bottomMargin:øspacing
				Layout.preferredHeight:root.height/4
				Layout.fillHeight:false
				Text {
					Layout.minimumWidth:øspacing*5
					Layout.preferredWidth:Layout.minimumWidth
					Layout.fillHeight:true
					verticalAlignment:   Text.AlignVCenter
					horizontalAlignment: Text.AlignRight
					text: formatDuration(elapsed)
					font: ɢtheme.details.timeFont
					color:ɢtheme.details.timeColor
				}
				Slider {
					Layout.fillWidth:true
					value:elapsed/duration
				}
				Text {
					Layout.minimumWidth:øspacing*5
					Layout.preferredWidth:Layout.minimumWidth
					Layout.fillHeight:true
					verticalAlignment:   Text.AlignVCenter
					horizontalAlignment: Text.AlignLeft
					text: formatDuration(duration-elapsed)
					font: ɢtheme.details.timeFont
					color:ɢtheme.details.timeColor
				}
			}
		}

		Rating {
			song: song
			Layout.rightMargin:     root.height * 0.1
			Layout.preferredWidth:  root.height * 0.8
			Layout.preferredHeight: root.height * 0.8
		}
	}
}
