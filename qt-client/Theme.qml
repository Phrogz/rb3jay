import QtQml 2.2

QtObject {
	property real uiScale: 0.8

	// Top bar of the app, with music controls
	property var header: ({
		height:     100*uiScale,
		backColor:  '#cccccc',
		textColor:  '#000000'
	})

	// The currently playing song
	property var details: ({
		backColor:  '#ffffff',
		textColor:  '#000000',
		timeColor:  '#66000000',
		titleFont:  Qt.font({ pointSize:22*uiScale, bold:true  }),
		artalbFont: Qt.font({ pointSize:16*uiScale, bold:false }),
		timeFont:   Qt.font({ pointSize:12*uiScale, bold:false })
	})

	// Bottom bar of the app, showing song details
	property var inspector: ({
		height:    100*uiScale,
		backColor: '#999999',
		textColor: '#333333',
		font:      Qt.font({ pointSize:16*uiScale })
	})

	// Headers above each song list
	property var titlebars: ({
		height:    30*uiScale,
		backColor: '#eeeeff',
		textColor: '#66000000',
		font:      Qt.font({ pointSize:14*uiScale, bold:true }),
	})

	// Row with song details
	property var songs: ({
		height:      20*uiScale,
		backColor:   '#fafafa',
		textColor:   '#000000',
		highlight:   '#ddeeff',
		font:        Qt.font({ pointSize:12*uiScale }),
		playedFont:  Qt.font({ pointSize:12*uiScale, italic:true }),
		playedColor: '#999999'
	})
}
