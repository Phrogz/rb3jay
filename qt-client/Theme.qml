import QtQml 2.2

QtObject {
	property var header: ({                               // Top bar of the app, with music controls
		height:     100,
		backColor:  '#cccccc',
		textColor:  '#000000'
	})
	property var details: ({                              // The currently playing song
		backColor:  '#ffffff',
		textColor:  '#000000',
		titleFont:  Qt.font({ pointSize:22, bold:true  }),
		artalbFont: Qt.font({ pointSize:16, bold:false })
	})
	property var inspector: ({                            // Bottom bar of the app, showing song details
		height:    100,
		backColor: '#999999',
		textColor: '#333333',
		font:      Qt.font({ pointSize:16 })
	})
	property var titlebars: ({                            // Headers above each song list
		height:    30,
		backColor: '#eeeeff',
		textColor: '#66000000',
		font:      Qt.font({ pointSize:14, bold:true }),
	})
	property var songs: ({                                // Row with song details
		height:      20,
		backColor:   '#eeeeee',
		textColor:   '#000000',
		font:        Qt.font({ pointSize:12 }),
		playedFont:  Qt.font({ pointSize:12, italic:true }),
		playedColor: '#999999'
	})
}
