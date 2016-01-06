function MyQueue(selector){
	this.$tbody = $(selector);
	var tbody = this.$tbody[0];

	tbody.addEventListener( 'dragenter', function(evt){
		this.classList.add('over');
		return false;
	}, false );

	tbody.addEventListener( 'dragover', function(evt){
		evt.dataTransfer.dropEffect = 'copy';
		if (evt.preventDefault) evt.preventDefault();
		this.classList.add('over');
		return false;
	}, false );

	tbody.addEventListener( 'dragleave', function(evt){
		this.classList.remove('over');
		return false;
	}, false );

	tbody.addEventListener( 'drop', function(evt) {
		this.classList.remove('over');
		if (evt.stopPropagation) evt.stopPropagation(); // Stops some browsers from redirecting.
		
		evt.dataTransfer.getData('Text').split('∆≈ƒ').forEach(function(id){
			var duplicate = document.getElementById(id).cloneNode(true);
			tbody.appendChild( duplicate );
		});

		return false;
	}, false );

}
