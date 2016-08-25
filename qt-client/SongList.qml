import QtQuick 2.7
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.3

Rectangle {
	function update(songs){
		ølist.model = songs;
	}

	function getSongs(){
		ɢapp.get('search',{ playlist:øplaylist.value(), query:øquery.text }, update)
	}

	ColumnLayout {
		anchors.fill:parent
		spacing:0

		Rectangle {
			color: ɢtheme.titlebarBGColor
			Layout.preferredHeight: ɢtheme.titlebarHeight
			Layout.fillWidth:true
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
					onTextChanged:getSongs()
				}
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
					width:parent.width
					height:ɢtheme.songHeight
				}
			}
		}
	}
}
