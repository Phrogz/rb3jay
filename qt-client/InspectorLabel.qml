import QtQuick 2.7
Text {
	property var rc

	width: ɢtheme.inspector.labelWidth
	height: parent.height/3
	x: rc[0]*((parent.width-4*ɢtheme.inspector.labelWidth)/4+ɢtheme.inspector.labelWidth) - ɢtheme.inspector.labelWidth/10
	y: rc[1]*parent.height/3

	font: ɢtheme.inspector.font
	color:ɢtheme.inspector.labelColor
	horizontalAlignment:Text.AlignRight
	verticalAlignment: Text.AlignVCenter
}
