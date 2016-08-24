import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3

Rectangle {
	function update(songs){
		console.log('SongList got',songs.length);
		ølist.model = songs;
	}

	function getSongs(){
		ɢapp.get('search',{ playlist:øplaylist.value(), query:øquery.text }, update)
	}

	ColumnLayout {
		anchors.fill:parent

		Rectangle {
			color: ɢtheme.titlebarBGColor
			Layout.preferredHeight: ɢtheme.titlebarHeight
			Layout.preferredWidth:  parent.width
			RowLayout {
				anchors.fill:parent
				ComboBox {
					id: øplaylist
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
					id: øquery
					Layout.preferredWidth:parent.width/2
					Layout.fillHeight:true
					onEditingFinished:getSongs()
				}
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
