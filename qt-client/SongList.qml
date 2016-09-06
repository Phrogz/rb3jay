import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3

Rectangle {
	color: ɢtheme.songs.backColor

	function update(songs){
		list.model = songs;
	}

	function getSongs(){
		get('search', { playlist:playlist.value(), query:query.text }, update)
	}

	ColumnLayout {
		anchors.fill:parent
		spacing:0

		Rectangle {
			color: ɢtheme.titlebars.backColor
			Layout.preferredHeight: ɢtheme.titlebars.height
			Layout.fillWidth:true
			RowLayout {
				anchors.fill:parent
				ComboBox {
					id: playlist
					Layout.preferredWidth:parent.width/2
					Layout.fillHeight:true
					model: ListModel {
					  ListElement { text:"(my preferred)"; value:"øilikeyø" }
						ListElement { text:"(all songs)";    value:"" }
					}
					onCurrentIndexChanged: getSongs()
					function value(){
						return ~currentIndex ? model.get(currentIndex).value : '';
					}
				}
				TextInput {
					id: query
					Layout.preferredWidth:parent.width/2
					Layout.fillHeight:true
					onTextChanged:getSongs()
				}
			}
		}

		ScrollView {
			frameVisible:false
			Layout.fillHeight:true
			Layout.fillWidth:true
			MultiSelectableListView {
				id: list
				model: []
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
