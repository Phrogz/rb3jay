import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3

Rectangle {
	color: ɢtheme.songs.backColor

	function update(songs){
		var next = songs.next || [];
		list.model = (songs.done || []).concat(next);
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
			MultiSelectableListView {
				id: list
				model: []
				property var selectedIndices: ({"0":1,"6":1,"7":1,"8":1})
				delegate: SongRow {
					id: row
					song: ɢsongdb.fromFile( modelData.file, modelData )
					past: !!modelData.event
					onIndexEchoChanged:    list.delegateByIndex[index] = row
					Component.onCompleted: list.delegateByIndex[index] = row
				}
			}
		}
	}
}
