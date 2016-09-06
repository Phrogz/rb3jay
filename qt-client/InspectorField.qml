import QtQuick 2.7
Item {
	property var rc
	property alias elide: text.elide
	property var value
	property bool varied: false
	property alias content: loader.sourceComponent

	width: (parent.width - ɢtheme.inspector.labelWidth*4)/4
	height: parent.height/3
	x: rc[0]*width + (rc[0]+1)*ɢtheme.inspector.labelWidth
	y: rc[1]*parent.height/3

	Text {
		id:    text
		anchors.fill:parent
		text:  varied ? '~' : (value || '-')
		font:  ɢtheme.inspector.font
		color: ɢtheme.inspector.textColor
		elide: Text.ElideRight
		visible: !content
		verticalAlignment: Text.AlignVCenter
	}

	Loader { id:loader; height:parent.height; width:parent.height }
}
