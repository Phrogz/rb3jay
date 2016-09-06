import QtQuick 2.7
import QtQuick.Controls 1.4

ListView {
	id: root
	model: []

	signal selectionChanged(var selectedModelData)

	property var idFunction: function(data){ return data.id }
	property var delegateByIndex: ({})
	property var øselectedIndices: ({})
	property int øselectionStart
	property int øselectionEnd
	property int ølastIndex: model.length-1 // TODO: support data models other than JS array

	Keys.onUpPressed: {
		if (event.modifiers & Qt.ShiftModifier) extendSelectionUp();
		else                                     selectUp();
	}

	Keys.onDownPressed: {
		if (event.modifiers & Qt.ShiftModifier) extendSelectionDown();
		else                                     selectDown();
	}

	function deselect(){
		ødeselectAll();
		øselectionStart = øselectionEnd = -1;
		øsignalModified();
	}

	function selectSolely(index){
		ødeselectAll();
		øselectedIndices[index] = 1;
		øselectionStart = øselectionEnd = index;
		øsignalModified();
	}

	function selectUp(){
		if (~øselectionEnd){
			selectSolely( Math.max(øselectionEnd-1,0) );
		} else console.warn("selectUp() requires an existing selection");
	}

	function selectDown(){
		if (~øselectionEnd){
			selectSolely( Math.min(øselectionEnd+1,ølastIndex) );
		} else console.warn("selectDown() requires an existing selection");
	}

	function selectExtend(index){
		if (øselectionStart==-1) return select(index);
		ødeselectAll();
		if (index>øselectionStart){
			for (var i=øselectionStart;i<=index;++i) øselectedIndices[i]=1;
		} else {
			for (var i=øselectionStart;i>=index;--i) øselectedIndices[i]=1;
		}
		øselectionEnd=index;
		øsignalModified();
	}

	function extendSelectionUp(){
		if (~øselectionStart){
			selectExtend( Math.max(øselectionEnd-1,0) );
		} else console.warn("extendSelectionUp() requires an existing selection");
	}

	function extendSelectionDown(){
		if (~øselectionStart){
			selectExtend( Math.min(øselectionEnd+1,ølastIndex) );
		} else console.warn("extendSelectionUp() requires an existing selection");
	}

	function selectToggle(index){
		øselectedIndices[index] = !øselectedIndices[index];
		if (øselectedIndices[index]) øselectionStart = øselectionEnd = index;
		// else if (index==øselectionStart) TODO: handle modifications to øselectionStart and øselectionEnd
		// else if (index==øselectionEnd) TODO: handle modifications to øselectionStart and øselectionEnd
		øsignalModified();
	}

	function isSelected(index){
		return !!øselectedIndices[index];
	}

	function ødeselectAll(){
		for (var i in øselectedIndices) delete øselectedIndices[i];
	}

	function øsignalModified(){
		var modelData = [];
		for (var i in øselectedIndices) modelData.push(model[i]);
		selectionChanged( modelData );
		ɢinspector.file = modelData[0] && modelData[0].file;
		for (var i=ølastIndex+1;i--;){
			if (delegateByIndex[i]) delegateByIndex[i].selected = !!øselectedIndices[i];
		}

	}
}
