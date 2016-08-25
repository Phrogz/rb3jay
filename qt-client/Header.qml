import QtQuick 2.7
import QtQuick.Layouts 1.1

Rectangle {
	color:  ɢtheme.header.backColor
	height: ɢtheme.header.height

	function update(status){
		if (status.volume>0) audiocontrol.volume = status.volume
		playcontrol.playingFlag = status.state=='play'
		ɢsongdb.setSongPlaying(status.file)
		songcontrol.elapsed  = status.elapsed || 0
		songcontrol.duration = status.time ? status.time[1] : 0
	}

	RowLayout {
		anchors.fill: parent
		spacing: 0
		PlayControl {
			id: playcontrol
			Layout.preferredWidth:2*ɢtheme.header.height
			Layout.minimumWidth:Layout.preferredWidth
			Layout.maximumWidth:Layout.preferredWidth
			Layout.preferredHeight:parent.height
			Layout.fillHeight:true
			onPlayingFlagChanged: post(playingFlag ? '/play' : '/paws')
			onNext: post('skip')
		}
		SongControl {
			id: songcontrol
			Layout.minimumWidth: 2*ɢtheme.header.height
			Layout.preferredWidth: parent.width*0.7
			Layout.preferredHeight:parent.height
			Layout.fillWidth:true
			Layout.fillHeight:true
		}
		AudioControl {
			id: audiocontrol
			Layout.minimumWidth: 2*ɢtheme.header.height
			Layout.preferredWidth: parent.width*0.3
			Layout.fillWidth:true
			Layout.fillHeight:true
			Layout.preferredHeight:parent.height
		}
	}
}
