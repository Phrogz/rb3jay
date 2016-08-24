import QtQml 2.2

QtObject {
    property real headerHeight:    100 // Top bar of the app, with music controls
    property real inspectorHeight: 100 // Bottom bar of the app, showing song details
    property real titlebarHeight:   30 // Headers above each song list
    property real songHeight:       20 // Row with song details

    property color headerBGColor:   '#cccccc'
    property color detailsBGColor:  '#ffffff'
    property color songBGColor:     '#eeeeee'
    property color titlebarBGColor: '#eeeeff'
    property color titlebarColor:   '#99000000'

    property font headerTitleFont: Qt.font({
        pixelSize:Math.round(headerHeight*0.20),
        bold:true
    })
    property font headerArtAlbFont: Qt.font({
        pixelSize:Math.round(headerHeight*0.15),
        bold:false
    })
    property font songFont: Qt.font({
        pixelSize:Math.round(songHeight*0.5)
    })
    property font titlebarFont: Qt.font({
        pixelSize:Math.round(titlebarHeight*0.5),
        bold:true
    })
}
