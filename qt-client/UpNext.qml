import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3


Rectangle {
	color: ɢtheme.songs.unusedSpace

	function update(songs){
		var next = songs.next || [];
		ølist.model = (songs.done || []).concat(next);
		label.text = "up next ("+next.length+" songs)";
	}

	ColumnLayout {
		anchors.fill:parent
		spacing:0

		Rectangle {
			color: ɢtheme.titlebars.backColor
			Layout.preferredHeight: ɢtheme.titlebars.height
			Layout.fillWidth:true
			Text {
				id: label
				anchors.fill:parent
				text: "up next"
				font:  ɢtheme.titlebars.font
				color: ɢtheme.titlebars.textColor
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment:   Text.AlignVCenter
			}
		}

		ScrollView {
			frameVisible:false
			Layout.fillHeight:true
			Layout.fillWidth:true
			ListView {
				id: ølist
				model: []
				delegate: SongRow {
					song: ɢsongdb.fromFile( modelData.file, modelData )
					past: !!modelData.event
					width:parent.width
					height:ɢtheme.songs.height
				}
			}
		}

	}
}
