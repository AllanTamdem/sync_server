"use strict";


//EditMetadata.showFromTable(data.file, data.key, data.metadata_file, createOptions);


var EditMetadata;

$(function(){


var FilesDao = (function(){

	var _filesTable = null

	function _init(filesTable){
		_filesTable = filesTable;
	}

	function getFileSize(key, callback){
		var url = '/s3/get_file_size?key=' + key
		url += "&bucket=" + $('#selected-bucket').val();

		$.get(url, function(result){
			callback(result.size);
		});
	}

	function fetchMetadata(metadataFile, callback){

		var url = '/s3/fetch_metadata?key=' + metadataFile.key;
		url += "&bucket=" + $('#selected-bucket').val();
		$.getJSON(url, function(result){
			callback(result);
		});
	}

	return {
		init: _init,
		getFileSize: getFileSize,
		fetchMetadata: fetchMetadata,
		deleteFile: function(file, key, message){

			$.ajax({
		    // url: '/s3/delete?key=' + key + '&cp=' + $('#filter_content_provider').val(),
		    url: '/s3/delete_files',
		    type: 'POST',
  			data: {
  				bucket: $('#selected-bucket').val(),
  				files: [key]
  			},
		    success: function(result) {
		    	if(result && result.error){
						toastr.error(result.error);
		    	}
		    	else{
						toastr.success(message || ('The file "' + file + '" has been deleted.'));
						_filesTable.refreshFiles();
						pubsub.publish("metadata-deleted-" + key);
		    	}
		    },
		    error: function(){
					toastr.error('An error occured while trying to delete the file "' + file + '".');
		    }
			});
		}
	}
})();

EditMetadata = (function () {

	var $modal = $('#modal-file-metadata');
	var $title = $('#modal-file-metadata .modal-title');
	var $btnDelete = $('#btn-metadata-delete');
	var $btnSave = $('#btn-metadata-save');
	var $result = $('#modal-file-metadata pre');
	var $tabForm = $('#tab-metadata-form');
	var $jsonErrors = $('#json-errors');
	
	var _defaultJsObj = {};
	var _fromDropZone = false;
	var _metadataFilesAvailable = [];
	var _metadataSelected = null;
	var _upload = null;
	var _filesDao = null;
	var _filesTable = null;

	var _templateKeys = SyncServer.metadata_template;

	var _jsObj;

	/**
	*
	* Editing the metadata in the Excel tab
	*
	*/
	var _ExcelTab = (function(){
		var $textarea = $("#textarea-excel");
		var _onChangeCallbacks = [];

		function _init(){

			//init events
			if ($textarea[0].addEventListener) {
			  $textarea[0].addEventListener('input', function() {
			  	_onChange();
			  }, false);
			} else if ($textarea[0].attachEvent) {
			  $textarea[0].attachEvent('onpropertychange', function() {		  	
			  	_onChange();
			  });
			}
		}

		function _onChange(){
			var jsObj = _get();
			_.each(_onChangeCallbacks, function(cb){
				cb(jsObj);
			})
		}

		function _set(jsObj){

			var flatObj = {};

			_.each(jsObj, function(v, k){
				if(_.isPlainObject(v)){
					_.each(v, function(v2, k2){
						flatObj[k + '.' + k2] = v2;
					});
				}
				else{
					flatObj[k] = v;
				}
			});

			var keys = _.keys(flatObj);
			var values = _.map(flatObj, function(v){
				if(_.isArray(v)){
					return v.join(', ')			
				}
				else if(_.isObject(v)){
					return JSON.stringify(v);
				}
				else {
					return v;
				}
			});

			$textarea.val(keys.join('\t') + '\n' + values.join('\t'));
		}

		function _get(){
			var text = $textarea.val();
			var lines = text.split('\n');

			var keys = _.filter(lines[0].split('\t'), function(v){
				return v.trim() != '';
			})

			var values = [];

			if(lines.length > 1){
				values = lines[1].split('\t');
			}

			var obj = {};

			_.each(keys, function(k, i){
				var templateKey = _.find(_templateKeys, function(tk){
					return tk.name == k;
				}) || {};

				var value;

				if(templateKey.type == 'array' ){

					if((values[i]||'').trim() != ''){
						value = _.map(values[i].split(','), function(v){
							return v.trim();
						});

						value = _.filter(value, function(item){
							return item != '';
						});
					}
					else{
						value = [];
					}
				}
				else if(templateKey.type == 'int' || templateKey.type == 'epoch' ){
					value = parseInt(values[i], 10) || null;
				}
				else if(templateKey.type == 'object' ){
					try {
						value = JSON.parse(values[i]);
					}
					catch(e){
						value = templateKey['default'] || {};
					}
				}
				else if(templateKey.type == 'boolean' ){
					if(values[i] == 'true' || values[i] == 'True'){
						value = true;
					}
					else if (values[i] == 'false' || values[i] == 'False'){
						value = false;
					}
					else{
						value = templateKey['default']
					}
				}
				else{
					value = values[i];
				}

				if(value === '' || value === null){
					if(templateKey['default'] === undefined)
						value = null;
					else
						value = templateKey['default'];
				}

				var indexDot = k.indexOf('.');

				if(indexDot == -1){
					obj[k] = value;
				}
				else{
					var key1 = k.substr(0, indexDot);
					var key2 = k.substr(indexDot+1);

					if(obj.hasOwnProperty(key1) == false){
						obj[key1] = {};
					}

					obj[key1][key2] = value;
				}
			})

			return obj;
		}


		return {
			init: _init,
			set: _set,
			get: _get,
			pushChangeCallback: function(cb){
				_onChangeCallbacks.push(cb);
			}
		};
	})();


	/**
	*
	* Editing the metadata in the Json tab
	*
	*/
	var _JsonTab = (function(){

		var $textarea = $("#textarea-json");
		var _onChangeCallbacks = [];

		function _init(){

			//init events
			if ($textarea[0].addEventListener) {
			  $textarea[0].addEventListener('input', function() {
			  	_onChange();
			  }, false);
			} else if ($textarea[0].attachEvent) {
			  $textarea[0].attachEvent('onpropertychange', function() {		  	
			  	_onChange();
			  });
			}
		}

		function _onChange(){
			var jsObj = _get();
			if(jsObj != 'ERROR'){
				$('#msg-json-non-valid').css('visibility', 'hidden');
				_.each(_onChangeCallbacks, function(cb){				
					cb(jsObj);
				});
			}else{
				$('#msg-json-non-valid').css('visibility', 'visible');
			}
		}

		function _set(jsObj){
			$textarea.val(JSON.stringify(jsObj, null, 4));
			$('#msg-json-non-valid').css('visibility', 'hidden');
		}

		function _get(){
	    	var json = $textarea.val();

	    	var result = 'ERROR';
	    	try{
	    		result = JSON.parse(json);
	    	}
	    	catch(e){

	    		if(console) console.log(e);
	    	}

	    	return result;
		}

		return {
			init: _init,
			set: _set,
			get: _get,
			pushChangeCallback: function(cb){
				_onChangeCallbacks.push(cb);
			}
		};
	})();


	/**
	*
	* Editing the metadata in the Form tab
	*
	*/
	var _FormTab = (function(){

		var $form = $('#tab-metadata-form');
		var _onChangeCallbacks = [];
		var _jsObj = {};
		var _datePickerFormatDate = 'DD/MM/YYYY';
		var _datePickerFormatEpoch = 'DD/MM/YYYY HH:mm';
		var _fieldsToWatch = [];

		function _init(){

			_.each(_templateKeys, function(k){
				if(k.showif){
					var splits = k.showif.split('=');
					if(splits.length == 2){
						_fieldsToWatch.push(splits[0]);
					}
				}
			});

			_fieldsToWatch = _.unique(_fieldsToWatch);

			_initForm();

			$(document).on("input", '#tab-metadata-form input', function(e) {
				var type = $(this).data('type');
				if(type != 'epoch' && type != 'date' && type != 'time'){
					_onChange($(this).data('key'), _.trim(this.value));
				}
			});
			$(document).on("change", '#tab-metadata-form select', function(e) {
				_onChange($(this).data('key'), this.value);
			});
			$(document).on("change", '#tab-metadata-form :checkbox', function(e) {
				_onChange($(this).data('key'), $(this).is(":checked"));
			});

		};

		function handleFieldToWatch(key, value){
			if(_.indexOf(_fieldsToWatch, key) == -1){
				return;
			}

			_.each(_templateKeys, function(k){

				if(k.showif && _.startsWith(k.showif, key + '=')){
					var splits = k.showif.split('=');

					// var conditions = splits[1].split(',');
					var conditions = _.map(splits[1].split(','),function(c){return c.trim();});

					if(_.indexOf(conditions, value) > -1 || value == ''){
						$('[data-key="' + k.name + '"]').removeAttr('readonly');
					}
					else{
						$('[data-key="' + k.name + '"]').attr('readonly', 'true');
					}
				}

			})
		}

		function _onChange(key, value){			

			handleFieldToWatch(key, value);

			var templateKey = _.find(_templateKeys, function(tk){
				return tk.name == key;
			}) || {};

			if(templateKey.type == 'array') {
				if(value.trim() != ''){
					value = _.map(value.split(','), function(v){
						return v.trim();
					});
				}
				else{
					value = [];
				}
			}
			else if(templateKey.type == 'int'){
				value = parseInt(value, 10) || null;
			}
			else if(templateKey.type == 'object'){
				try {
					value = JSON.parse(value);
				}
				catch(e){
					value = templateKey['default'] || {};
				}
			}

			if(value === '' || value === null){
				if(templateKey['default'] === undefined)
					value = null;
				else
					value = templateKey['default'];
			}

			var indexDot = key.indexOf('.');

			if(indexDot == -1){
				_jsObj[key] = value;
			}
			else{
				var key1 = key.substr(0, indexDot);
				var key2 = key.substr(indexDot+1);

				if(_jsObj.hasOwnProperty(key1) == false){
					_jsObj[key1] = {};
				}

				if(value == null){
					_jsObj[key1][key2] = undefined;
				} else{
					_jsObj[key1][key2] = value;
				}

			}

			try{
				if(value != null
					&& key == 'validationPlatformData.mediaUrl'
					&& _jsObj['validationPlatformData']['cid'] == null){
					_jsObj['validationPlatformData']['cid'] = undefined;
				}
				else if(value != null && key == 'validationPlatformData.cid'
					&& _jsObj['validationPlatformData']['mediaUrl'] == null){
					_jsObj['validationPlatformData']['mediaUrl'] = undefined;
				}
			}catch(ex){}


			_.each(_onChangeCallbacks, function(cb){				
				cb(_jsObj);
			});
		}


		function _initForm(){

			var nbColumns = 3;

			// var arraysKeys = Orange.splitArray(_templateKeys, 2);
			var arraysKeys = _.chunk(_templateKeys, Math.ceil(_templateKeys.length / nbColumns));

			var html = '<div class="row">';

			_.each(arraysKeys, function(keys){
				html += '<div class="col-lg-' + (12 / nbColumns) + '">';
				html += '<form class="form-horizontal"  autocomplete="off">';
				_.each(keys, function(k){

					var additionalInfo = '';
					if(k.info){
						additionalInfo = ' <i class="fa fa-info-circle" data-container="body" data-toggle="tooltip" title="' + k.info + '"></i>'
					}

					html += '<div class="form-group" >';
					html += ' <label for="metadata-input-' + k.name + '" class="col-sm-6 control-label">';
					html += k.name.replace('.', '<br>.') + additionalInfo + '</label>';
					html += ' <div class="col-sm-6">';


					if(k.options && k.options.length > 0){
						html += '  <select class="form-control" data-key="' + k.name + '" id="metadata-input-' + k.name + '">';
						_.each(k.options, function(o){
							if(k['default'] && k['default'] == o){
								html += '<option selected="selected" value="' + o + '">' + o + '</option>';
							}
							else{
								html += '<option value="' + o + '">' + o + '</option>';
							}
						});
						html += '  </select>';

					}
					else if (k.name == 'size'){

						html += ' <div class="input-group">'
						html += '  <input type="text" class="form-control" data-key="' + k.name + '" id="metadata-input-' + k.name + '">';
						html += ' 	<span class="calculate-size input-group-addon" style="cursor:pointer" >'
						html += ' 		<i class="ace-icon fa fa-calculator" title="click to calculate the size of the file automatically" data-container="body" data-toggle="tooltip"></i>'
						html += ' 	</span>'
						html += ' </div>'

					}
					else if(k.type == 'epoch' || k.type == 'date' || k.type == 'time') {
						html += '<div class="input-group">';

						var title = '';
						if(k.type == 'epoch'){
							title = 'title="Epoch time: null"';
						}

						html += '	<input type="text" data-type="' + k.type + '" class="form-control metadata-timepicker" data-key="' + k.name + '" id="metadata-input-' + k.name + '" ' + title + ' data-placement="top">';
						html += '	<span class="input-group-addon">';
						if(k.type == 'epoch' || k.type == 'time'){
							html += '		<i class="fa fa-clock-o bigger-110"></i>';
						}
						else{
							html += '		<i class="fa fa-calendar bigger-110"></i>';
						}
						html += '	</span>';					
						html += '</div>';
						// html += '<span class="help-block">UTC: 01/28/2015 11:45 AM</span>';
					}
					else if(k.type == 'boolean'){
						// html += '  <input type="checkbox" data-key="' + k.name + '" id="metadata-input-' + k.name + '">';

						html += '<div class="checkbox"><label style="padding-left: 10px;">'
						html += '<input data-key="' + k.name + '" id="metadata-input-' + k.name + '" name="form-field-checkbox" type="checkbox" class="ace">';
						html += '<span class="lbl"></span></div>';
					}
					else {
						html += '  <input type="text" class="form-control" data-key="' + k.name + '" id="metadata-input-' + k.name + '">';
					}
					html += ' </div>';
					html += '</div>';
				});
				html += '</form>';
				html += '</div>';
			})

			html += '</div>';

			$tabForm.html(html);


			$tabForm.find('[data-toggle="tooltip"]').tooltip();

			$('.metadata-timepicker').each(function(){

				var format = _datePickerFormatDate;

				if($(this).data('type') == 'epoch' || $(this).data('type') == 'time'  ){
					format = _datePickerFormatEpoch;
				}

				if($(this).data('type') == 'epoch'){
					$(this).tooltip({container:'body'});
				}


				var key = $(this).data('key');
				$(this).datetimepicker({
					format: format,
					useCurrent: false,
					showClear: true,
					showTodayButton: true,
					defaultDate: moment(moment().format('DD/MM/YYYY'), 'DD/MM/YYYY')
				})
				.next().on(ace.click_event, function(){
					$(this).prev().focus();
				});


        $(this).on("dp.change", function(e) {
        	var type = $(this).data('type');
        	var key = $(this).data('key');
        	var date = $(this).data("DateTimePicker").date();
        	var value = null;
        	if(date != null){
						if(type == 'epoch'){
		        			value = date.unix();
						}
						else{
		        			value = date.format();
						}
        	}
        	_onChange(key, value);

					if(type == 'epoch'){
			        	$(this).attr('title', 'Epoch time: ' + value)
			        	.tooltip('fixTitle')
			        	.tooltip('hide');
					}
        });
			});
		}


		function _set(jsObj) {
			_jsObj = jsObj;

			$form.find('input, select').val(''); //reset everything

			var inputs = {};

			_.each(jsObj, function(v, k){
				if(_.isPlainObject(v)){
					_.each(v, function(v2, k2){
						inputs[k + '.' + k2] = v2;
					});
				}
				else{
					inputs[k] = v;
				}
			})


			_.each(inputs, function(v, k){
				var templateKey = _.find(_templateKeys, function(tk){
					return tk.name == k;
				}) || {};

				var $input = $form.find('[data-key="' + k + '"]');

				if(templateKey.type == 'date' || templateKey.type == 'epoch' || templateKey.type == 'time'){

					var date;
					if(templateKey.type == 'epoch'){
						var date = moment(v, 'X');
					}
					else{
						var date = moment(v);
					}

					if(date.isValid()){
						$input.data("DateTimePicker").date(date);
					}
					else{
						$input.data("DateTimePicker").date(null);
					}
				}
				else if(templateKey.type == 'boolean'){
					$input.prop('checked', v);
				}
				else if(_.isArray(v)){
					$input.val(v.join(', '));
				}
				else if(_.isObject(v)){
					$input.val(JSON.stringify(v));
				}
				else{
					$input.val(v);
				}
			});


			_.each(_fieldsToWatch, function(k){
				var value = $('[data-key="' + k + '"]').val();
				handleFieldToWatch(k, value);
			})

		}


		return {
			init: _init,
			set: _set,
			pushChangeCallback: function(cb){
				_onChangeCallbacks.push(cb);
			}
		};

	})();

	function _init(upload, filesDao, filesTable){
		_upload = upload;
		_filesDao = filesDao;
		_filesTable = filesTable;
		initEventSaving();
		initEventDelete();
		setDefaultJson();

		_JsonTab.init();
		_ExcelTab.init();
		_FormTab.init();

		$('#modal-file-metadata a[data-toggle="tab"]').on('show.bs.tab', function(e){
			var target = $(e.target).attr('href');
			if(target == '#tab-metadata-form'){
				_FormTab.set(_jsObj);
			}
			else if(target == '#tab-metadata-excel'){
				_ExcelTab.set(_jsObj);
			}
			else if(target == '#tab-metadata-json'){
				_JsonTab.set(_jsObj);
			}
		});

		$(document).on("click", '.calculate-size', function(e) {
			var $btn = $(this);			
			$btn.find('i').removeClass('fa-calculator').addClass('fa-circle-o-notch fa-spin');
			var fileKey = _.trimRight(_metadataSelected.key, '.json');
			_filesDao.getFileSize(fileKey, function(size){
				$btn.find('i').addClass('fa-calculator').removeClass('fa-circle-o-notch fa-spin');
				if(size == null){
					toastr.info('The size of the file ' + fileKey + ' couldn\'t be calculated');
				}
				else{
					$('.calculate-size').closest('.input-group').find('input').val(size).trigger("input");
				}
			});
			return false;
		});

		_JsonTab.pushChangeCallback(function(jsObj){
			_jsObj = jsObj;
		});
		_ExcelTab.pushChangeCallback(function(jsObj){
			_jsObj = jsObj;
		});
		_FormTab.pushChangeCallback(function(jsObj){
			_jsObj = jsObj;
		});
	}

	function setDefaultJson(){
		_defaultJsObj = {};

		function setValue(obj, key, value){
			var indexDot = key.indexOf('.');

			if(indexDot == -1){
				obj[key] = value;
			}
			else{
				var key1 = key.substr(0, indexDot);
				var key2 = key.substr(indexDot+1);

				if(obj.hasOwnProperty(key1) == false){
					obj[key1] = {};
				}

				obj[key1][key2] = value;
			}
		}

		_.each(_templateKeys, function(k){					
			if(k['default'] !== undefined){
				setValue(_defaultJsObj, k.name, k['default']);
			}
			else if (k.type == 'string' ) {
				setValue(_defaultJsObj, k.name, null);
			}
			else if (k.type == 'int' ) {
				setValue(_defaultJsObj, k.name, null);
			}
			else if (k.type == 'epoch' ) {
				setValue(_defaultJsObj, k.name, null);
			}
			else if (k.type == 'array' ) {
				setValue(_defaultJsObj, k.name, []);	
			}
			else {
				setValue(_defaultJsObj, k.name, null);
			}	
		});

		try{
			_defaultJsObj['validationPlatformData']['cid'] = undefined
		}
		catch(ex){
		}
	}


	function displayMetadata(metadataObj, createOptions){

		if(metadataObj){
			_.each(_templateKeys, function(k){
				//if this field is not set and there is a default value, then we set it to the default value.
				if(metadataObj[k.name] == undefined && k['default'] !== undefined){
					metadataObj[k.name] = k['default'];
				}
			});
		}

		var jsObj = metadataObj || _.cloneDeep(_defaultJsObj);

		_.each(createOptions || {}, function(v, k){
			if(v !== undefined){
				jsObj[k] = v;
			}
		})

		_JsonTab.set(jsObj);
		_ExcelTab.set(jsObj);
		_FormTab.set(jsObj);
	}


	function showError(errors, schema){

		if(schema){
			var msg = '<b>Error.</b> This metadata information is not valid. <a id="lnk-see-schema" href="#">See validation schema</a>.';
			$jsonErrors.html('<div class="alert alert-danger">'+msg+'</div>');
			$jsonErrors.append('<pre style="display:none;">' + schema + '</pre>');

			$('#lnk-see-schema').click(function(){
				var visible = $jsonErrors.find('pre').is(':visible');
				if(visible){
					$('#lnk-see-schema').html('See validation schema');
					$jsonErrors.find('pre').hide();
				}else{
					$('#lnk-see-schema').html('Hide validation schema');
					$jsonErrors.find('pre').show();
				}
			});
		}
		else{
			var msg = "<b>Error :</b><br>" + errors.join('<br>');
			$jsonErrors.html('<div class="alert alert-danger">'+msg+'</div>');
		}
	}



	function saveMetadata(key, metadata){
		var initialButtonText = $("#btn-metadata-save").html();
		$("#btn-metadata-save").button('loading')
		$.post("/s3/set_metadata", {
			key: key,
			bucket: $('#selected-bucket').val(),
			metadata: metadata}
		)
		.done(function(result) {
			if(result.errors.length > 0){
      	showError(result.errors, result.schema);
			}
			else{
				toastr.success('The metadata has been saved.');
				_filesTable.refreshFiles();
				$modal.modal('hide');
				pubsub.publish("metadata-saved-" + key);
			}
		})
		.complete(function(){
			$('#btn-metadata-save').button('reset');
			setTimeout(function(){
				$('#btn-metadata-save').html(initialButtonText);
			},1);
		});
	}

	function validateMetadata(metadata, callback){		
		$("#btn-metadata-save").attr('disabled', 'disabled');
		$.post("/s3/validate_metadata", {metadata:metadata})
		.done(function(result) {
			$("#btn-metadata-save").removeAttr('disabled');
			if(result.errors.length > 0){
	      showError(result.errors, result.schema);
			}
			else{
				callback();
			}
		});

	}

	//Saving metadata
	function initEventSaving(){

		$(document).on("click", '#btn-metadata-save', function() {

	    	if(_JsonTab.get() == 'ERROR'){
	    		alert("unable to parse this JSON");

	  			return false;
	    	}
			$jsonErrors.html('');

			var data = {
				key: _metadataSelected.key,
				metadata: JSON.stringify(_jsObj, null, 2)
			};

			saveMetadata(data.key, data.metadata);

			return false;
	    });
	}

	function initEventDelete(){

	    $(document).on("click", '#btn-metadata-delete', function(e) {
	    	_filesDao.deleteFile(_metadataSelected.file,
	    		_metadataSelected.key,
	    		'The metadata has been deleted.');
	    	
				$modal.modal('hide');

	    	return false;
	    });
	}

	 
	return {
  		init: _init,
  		saveMetadata: saveMetadata,
  		showFromTable: function(fileName, fileKey, metaFileObj, createOptions){
			$title.html('Metadata for <b>' + fileName + '</b>');

    		if(metaFileObj){
      		$btnDelete.show();
      		$btnSave.html('Save');
      		_metadataSelected = metaFileObj;
        	$modal.find('.btn').attr('disabled', 'disabled');
        	_filesDao.fetchMetadata(metaFileObj, function(result){

        		if(result.error){
        			toastr.error(error);
        			displayMetadata(null);
        		}
        		else{
        			var metadata = null
        			try{
        				metadata = JSON.parse(result.body);
        			}
        			catch(e){
        				toastr.error('The fetched metadata couldn\'t be parsed');
        			}
        			displayMetadata(metadata);
        		}

        		$modal.find('.btn').removeAttr('disabled');
        	});
        }
        else{
        	$btnDelete.hide();
      		$btnSave.html('Create');
        	_metadataSelected = { key : fileKey + '.json', file: fileName + '.json' };
					displayMetadata(null, createOptions);					
					$("#btn-metadata-save").removeAttr('disabled');
        }

        _fromDropZone = false;
        $jsonErrors.html('');
        $modal.modal('show');
	  	},
	  	setMetadataFilesAvailable: function(metadataFilesAvailable){
	  		_metadataFilesAvailable = metadataFilesAvailable;
	  	},
	  	getMetadataFilesAvailable: function(){
	  		return _metadataFilesAvailable;
	  	}
	}; 
})();

var FilesTable = (function(){
	return {
		refreshFiles: function(){
			// console.log('refreshFiles');
		}
	}
})();

EditMetadata.init(null, FilesDao, FilesTable);
FilesDao.init(FilesTable);

});