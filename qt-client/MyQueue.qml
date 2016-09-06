import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3

Rectangle {
	property bool active: true

	color: ɢtheme.songs.backColor

	function update(songs){
		ølist.model = songs;
		label.text = (ɢactiveUser ? (ɢactiveUser+"'s") : 'my') + " queue ("+songs.length+" songs)";
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
				text: "my queue"
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
			MultiSelectableListView {
				id: ølist
				model: []
				property var selectedIndices: ({})
				delegate: SongRow {
					id: row
					song: ɢsongdb.fromFile( modelData.file, modelData )
					onIndexEchoChanged:    list.delegateByIndex[index] = row
					Component.onCompleted: list.delegateByIndex[index] = row
				}
			}
		}

	}
}
