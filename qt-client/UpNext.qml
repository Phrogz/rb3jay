import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3


Rectangle {
	function update(songs){
		var next = songs.next || [];
		ølist.model = (songs.done || []).concat(next);
		label.text = "up next ("+next.length+" songs)";
	}

	ColumnLayout {
		anchors.fill:parent

		Rectangle {
			color: ɢtheme.titlebarBGColor
			Layout.preferredHeight: ɢtheme.titlebarHeight
			Layout.preferredWidth:  parent.width
			Text {
				id: label
				anchors.fill:parent
				text: "up next"
				font:  ɢtheme.titlebarFont
				color: ɢtheme.titlebarColor
				horizontalAlignment: Text.AlignHCenter
				verticalAlignment:   Text.AlignVCenter
			}
		}

		ScrollView {
			frameVisible:true
			Layout.fillHeight:true
			Layout.fillWidth:true
			ListView {
				id: ølist
				model: []
				delegate: SongRow {
					song: ɢsongdb.fromFile( modelData.file, modelData )
					width:parent.width
					height:ɢtheme.songHeight
				}
			}
		}

	}
}
