import QtQuick 2.7
import QtQuick.Layouts 1.3

Rectangle {
	id: root
	color:  selected ? ( focused ? ɢtheme.songs.activeFocus : ɢtheme.songs.inactiveFocus) : ɢtheme.songs.backColor
	width:  parent.width
	height: ɢtheme.songs.height

	property QtObject song
	property bool past: false
	property bool selected:  ListView.view.isSelected(index)
	property bool focused:   ListView.view.focus || ListView.view.activeFocus
	property bool indexEcho: index
	onIndexEchoChanged: selected = ListView.view.isSelected(index)

	signal adjustRating(var song)
	signal hideRating

	MouseArea {
		anchors.fill:parent
		onClicked: {
			var view = root.ListView.view;
			if      (mouse.modifiers & Qt.ShiftModifier)   view.selectExtend(index);
			else if (mouse.modifiers & Qt.ControlModifier) view.selectToggle(index);
			else                                           view.selectSolely(index);
			view.forceActiveFocus(Qt.MouseFocusReason);
		}
	}

	RowLayout {
		id: songrow
		anchors.fill: parent

		property font  rowfont:  ɢtheme.songs[past ? 'playedFont'  : 'font']
		property color rowcolor: ɢtheme.songs[past ? 'playedColor' : 'textColor']

		Rating {
			song: root.song
			Layout.preferredWidth:  root.height
			Layout.preferredHeight: root.height
		}

		Text {
			id: title
			text:  song && song.title || '-'
			font:  songrow.rowfont
			color: songrow.rowcolor
			elide: Text.ElideRight
			rightPadding: root.height/2
			maximumLineCount: 1
			verticalAlignment: Text.AlignVCenter
			Layout.minimumWidth: root.height
			Layout.preferredWidth: root.width * 0.5
			Layout.fillWidth:  true
			Layout.fillHeight: true
		}

		Text {
			text:  song && song.artist || '-'
			font:  songrow.rowfont
			color: songrow.rowcolor
			elide: Text.ElideMiddle
			rightPadding: root.height/2
			maximumLineCount: 1
			verticalAlignment: Text.AlignVCenter
			Layout.minimumWidth: root.height
			Layout.preferredWidth: root.width * 0.3
			Layout.fillWidth:  true
			Layout.fillHeight: true
		}

		Text {
			text:  formatDuration(song && song.time)
			font:  songrow.rowfont
			color: songrow.rowcolor
			rightPadding: root.height/4
			maximumLineCount: 1
			verticalAlignment: Text.AlignVCenter
			horizontalAlignment: Text.AlignRight
			Layout.minimumWidth:   root.height
			Layout.preferredWidth: root.width * 0.1
			Layout.fillWidth:  true
			Layout.fillHeight: true
		}
	}
}
