"use strict";

$(function(){

Dropzone.autoDiscover = false;

var _modifyType = null;

/**
*
* 
*
*/
var FilesDao = (function(){

	var _filesTable = null

	function _init(filesTable){
		_filesTable = filesTable;
	}

	function getFileSize(key, callback){
		var url = '/s3/get_file_size?key=' + key + '&cp=' + $('#filter_content_provider').val();
		$.get(url, function(result){
			callback(result.size);
		});
	}

	return {
		init: _init,
		getFileSize: getFileSize,
		deleteFile: function(file, key, message){
			$.ajax({
		    url: '/s3/delete?key=' + key + '&cp=' + $('#filter_content_provider').val(),
		    type: 'delete',
		    success: function(result) {
		    	if(result.error){
						toastr.error(result.error);
		    	}
		    	else{
						toastr.success(message || ('The file "' + file + '" has been deleted.'));
						_filesTable.refreshFiles();
		    	}
		    },
		    error: function(){
					toastr.error('An error occured while trying to delete the file "' + file + '".');
		    }
			});
		}
	}
})();

/**
*
* Manage the editing of metadata
*
*/
var ModalMetadata = (function () {

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
		$.post("/s3/set_metadata", {key:key, cp: $('#filter_content_provider').val(), metadata:metadata})
		.done(function(result) {
			if(result.errors.length > 0){
      	showError(result.errors, result.schema);
			}
			else{
				toastr.success('The metadata has been saved.');
				_filesTable.refreshFiles();
				$modal.modal('hide');
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

			if(_fromDropZone) {
				var uploadingFile = _.find(_upload.getDropZone().files, function(f){
					return f.key + '.json' == data.key && f.upload.progress < 100;
				});

				if(uploadingFile){

					validateMetadata(data, function(){
						uploadingFile.metadata = data;
						$(uploadingFile.previewElement)
						.find('.dz-metadata')
						.removeClass('btn-primary').addClass('btn-info')
						.html('Edit metadata');
						$modal.modal('hide');
					});
				}
				else{
					saveMetadata(data.key, data.metadata);
				}
			}
			else{
				saveMetadata(data.key, data.metadata);
			}

			return false;
	    });
	}

	function initEventDelete(){

	    $(document).on("click", '#btn-metadata-delete', function(e) {

	    	if(_fromDropZone){

	    		//find from the files being uploaded
				var uploadingFile = _.find(_upload.getDropZone().files, function(f){
					return f.key + '.json' == _metadataSelected.key 
					&& f.upload.progress < 100;
				});

				if(uploadingFile){				
					uploadingFile.metadata = undefined;
					$(uploadingFile.previewElement)
					.find('.dz-metadata')
					.removeClass('btn-info').addClass('btn-primary')
					.html('Create metadata');
				}
				else{
			    	_filesDao.deleteFile(_metadataSelected.file,
			    		_metadataSelected.key,
			    		'The metadata has been deleted.');
				}
	    	}
	    	else{
		    	_filesDao.deleteFile(_metadataSelected.file,
		    		_metadataSelected.key,
		    		'The metadata has been deleted.');
	    	}
	    	
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
        	$.getJSON(metaFileObj.url_for_read, function(json){
        		displayMetadata(json);
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
	  	showFromDropZone: function(fileName, fileKey, createOptions){
	    	var metadataKey = fileKey + '.json';

					$title.html('Metadata for <b>' + fileName + '</b>');

					var metadata = _.find(_metadataFilesAvailable, function(fm){
						return fm.key == metadataKey;
					});

	        if(metadata){
	        	$btnDelete.show();
	      		$btnSave.html('Save');
	        	_metadataSelected = metadata;
	        	$modal.find('.btn').attr('disabled', 'disabled');
	        	$.getJSON(metadata.url_for_read, function(json){
	        		displayMetadata(json);
	        		$modal.find('.btn').removeAttr('disabled');
	        	});
	        }
	        else{

						var uploadingFile = _.find(_upload.getDropZone().files, function(f){
							return f.key + '.json' == metadataKey 
							&& f.upload.progress < 100
							&& f.metadata;
						});

						if(uploadingFile){
							_metadataSelected = uploadingFile.metadata;
							displayMetadata(JSON.parse(_metadataSelected.metadata + ""));

			        		$btnDelete.show();
			      			$btnSave.html('Save');
						}
						else {
			    			_metadataSelected = { key : metadataKey, file: fileName + '.json' };

			    			displayMetadata(null, createOptions);

			        		$btnDelete.hide();
			      			$btnSave.html('Create');
						}
						$("#btn-metadata-save").removeAttr('disabled');
	        }

	        _fromDropZone = true;
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


/**
*
*
*
*/
var RunningJobs = (function(){	
	var _pollingJobsInfo = false;
	var _runningJobs = [];

	var _filesTable = null;

	function _init(filesTable){
		_filesTable = filesTable;
	}


	function refreshJobs(){

		$.get("/s3/get_jobs")
		.done(function(data) {
			if(data.jobs.length > 0){

				_pollingJobsInfo = true;

				var html = '<div class="alert alert-info" role="alert">'
	    			+ '<strong>Running processes:</strong>'
		    		+ '<ul>';

		    	_.each(data.jobs, function(w){
		    		if(w.type == 'queued'){
		    			html += '<li>Queued : ' + w.description + '</li>';
		    		}
		    		else{
		    			html += '<li>' + w.description + '</li>';
		    		}
		    	});
		    	html += '</ul>'
	    			+ '</div>';

				$('#jobs').html(html);

			}
			else{
				_pollingJobsInfo = false;
				
				$('#jobs').html('');
			}

			//update list of jobs running
			//and inform of finished jobs

			var jobIdsToRemove = [];

			_.each(_runningJobs, function(page_job){

				if(_.any(data.jobs, function(job){
					return job.job_id == page_job.job_id;
				})){
					//the job is still running
				}
				else {
					toastr.success('Process completed: ' + page_job.params.description);
					jobIdsToRemove.push(page_job.job_id);
				}
			});

			if(jobIdsToRemove.length > 0){				
				_filesTable.refreshFiles();

				//remove the finished jobs from the list of running jobs
				_.each(jobIdsToRemove, function(jobIdToRemove){
					var index = $.inArray(jobIdToRemove, _.pluck(_runningJobs, 'job_id'));

					_runningJobs.splice(index, 1);
				});
			}

			setTimeout(function(){
				if(_pollingJobsInfo){
					refreshJobs();
				}
			}, 1000);
		});
	}

	return {
		init: _init,
		refreshJobs: refreshJobs,
		push: function(job){
			_runningJobs.push(job);
		},
		setPollingJobsInfo: function(flag){
			_pollingJobsInfo = flag;
		}
	};
})();


/**
*
*
*
*/
var FilesTable = (function(){

	var _nbLoading = 0;
	var _filesToModify = [];
	var _initialModifyFileForm = $('#modal-modify-file form').html();
	var _table = null;

	var _modalMetadata = null;
	var _filesDao = null;
	var _runningJobs = null;

	function _init(modalMetadata, filesDao, runningJobs){
		_modalMetadata = modalMetadata;
		_filesDao = filesDao;
		_runningJobs = runningJobs;

		setTimeout(initTable,0);
		

	    $(document).on("click", "#btn-refresh", function() {
	        refreshFiles();
	        return false;
	    });

	    $(document).on("change", "#chk-details", function() {
	        refreshFiles();
	        return false;
	    });

	    //Editing metadata from the table
	    $(document).on("click", '.btn-file-metadata', function(e) {
	        var data = _table.api().row($(this).closest('tr')[0]).data();

	        var createOptions;

	        if(!data.metadata_file){
	        	createOptions = {
		        	//mimeType : data.head.content_type,
		        	size : data.head.content_length
	        	}
	        }

	        _modalMetadata.showFromTable(data.file, data.key, data.metadata_file, createOptions);

	        return false;
	    });


		// select a row (a file)
	    $(document).on("change", "[data-action=check]", function() {
	         if($(this).is(':checked')){
	         	$(this).closest('tr').addClass('info');
	         	$('#btn-action').removeClass('btn-default').addClass('btn-info');
	         	$('[data-action="delete"]').removeClass('disabled-link');
	         	$('[data-action="modify"]').removeClass('disabled-link');

	         }
	         else{
	         	$(this).closest('tr').removeClass('info');

	         	if($('#table-files tbody tr.info').length == 0){
	         		$('#btn-action').removeClass('btn-info').addClass('btn-default');         		
	         		$('[data-action="delete"]').addClass('disabled-link');
	         		$('[data-action="modify"]').addClass('disabled-link');
	         	}
	         }
	    });


		//delete a single file
		$(document).on("click", ".btn-delete-file", function() {
			var file = $(this).data('file');
			if(confirm('Are you sure that you want to delete the file "' + file + '" ?')){
				_filesDao.deleteFile(file, $(this).data('key'));
			}
		});

	    //delete several files
	    $(document).on("click", "[data-action=delete]", function() {
	    	var files = $('#table-files tbody input:checked').map(function(){
	        	return _table.api().row($(this).closest('tr')).data();
	    	}).get();

	    	if(files.length == 0){
	    		alert('Please select at least one file');
	    		return;
	    	}

	    	var message = 'Are you sure that you want to delete these files?\n - '

	    	if(confirm(message + _.pluck(files, 'file').join('\n - '))){

	    		_.each(files, function(file){
	    			_filesDao.deleteFile(file.file, file.key);
	    		});
	    	}
	    });


		//modify a single file
		$(document).on("click", ".btn-modify-file", function() {

      var data = _table.api().row($(this).closest('tr')).data();

			_filesToModify = [{
				file: data.key,
				key: data.key
			}];

			_modifyType = 'single';

			$('#modal-modify-file form').html(_initialModifyFileForm);

			$('#new-path').val(data.key);

			$('#label-modify-path').html('Modify file path and name:');
			$('#title-modify').html('Modify file ' + data.file);

      $("#btn-modify-file-submit").button('reset');
			$('#modal-modify-file').modal('show');
		});


		//modify several files
	    $(document).on("click", "[data-action=modify]", function() {
	    	var files = $('#table-files tbody input:checked').map(function(){
	        	return _table.api().row($(this).closest('tr')).data();
	    	}).get();

	    	if(files.length == 0){
	    		alert('Please select at least one file');
	    		return;
	    	}	    	

				_modifyType = 'bulk';

	    	_filesToModify = _.map(files, function(file){
	    		return {
					file: file.file,
					key: file.key
	    		}
	    	});


			$('#modal-modify-file form').html(_initialModifyFileForm);

			var currentPath = $('#filter_content_provider').val();
			if(false == _.endsWith(currentPath, '/')){
				currentPath += '/';
			}
			$('#new-path').val(currentPath);

			$('#label-modify-path').html('Enter new folder path for these files:');
			$('#title-modify').html('Bulk file modification');

	        $("#btn-modify-file-submit").button('reset');
			$('#modal-modify-file').modal('show');

	    });

	

	    // submit modify file
		$(document).on("click", "#btn-modify-file-submit", function() {
			modifyFile();
	        return false;
	    });
		$(document).on("submit", "#modal-modify-file form", function() {
			modifyFile();
	        return false;
	    });


		//apply filter value from localStorage
		
		var storage = $.localStorage;
		var filter_key = 'repo_filter_content_provider';
		if(storage.isSet(filter_key)){
			var val = storage.get(filter_key);
			if(-1 < $.inArray(val,$("#filter_content_provider > option").map(function() { return $(this).val(); }) )){
				$('#filter_content_provider').val(val);
			}
		}

		$(document).on("change", "#filter_content_provider", function() {			
	        refreshFiles();
	        PathChooser.set($('#filter_content_provider').val());
	        storage.set(filter_key, $('#filter_content_provider').val())
	    });

	}



	function initTable(){

		// creating a custom sort
		$.extend($.fn.dataTableExt.oSort, {
		    "custom-sort-asc": function (a, b) {
		    	var sizeA = $(a).data('sort');
		    	var sizeB = $(b).data('sort');
		        return ((sizeA < sizeB) ? -1 : ((sizeA > sizeB) ? 1 : 0));
		    },
		    "custom-sort-desc": function (a, b) {
		    	var sizeA = $(a).data('sort');
		    	var sizeB = $(b).data('sort');
		        return ((sizeA < sizeB) ? 1 : ((sizeA > sizeB) ? -1 : 0));
		    }
		});

		// setup the table
	    _table = $('#table-files').dataTable({
	    	ajax: {
	    		url:'/s3/get_files',
	    		data: function (d) {
			        d.filter = $('#filter_content_provider').val();
			        d.detailed = $("#chk-details").is(':checked');
			    },
	    		error: function(){},
	    		complete: function(result){
	    			if(result && result.responseJSON){

	    				if(result.responseJSON.err){
	    					toastr.error(result.responseJSON.err);
	    				}

		    			if(result.responseJSON.detailed == true){	    				
		    				_table.api().column(5).visible(true);
		    				_table.api().column(6).visible(true);
		    			}
		    			else{
		    				_table.api().column(5).visible(false);
		    				_table.api().column(6).visible(false);
		    			}
	    			}
	    		}
	    	},
	    	fnInitComplete: function(settings, result) {
	    		populateMetadaFilesAvailable(result);
		    },
	    	dom: '<"table-toolbar">frtip',
	    	columns: [{
	                visible: false,
	                data: 'file'
	            },{
	                visible: false,
	                data: 'head',
	                render: function(data){
	                	if(data && data.content_length){
	                		return data.content_length;
	                	}
	                	return 0;
	                }
	            },{
	                orderable:      false,
	                data:           null,
	                render: function(data, type, row){
	                	return '<input data-key="' + row.key + '" data-file="' + row.file + '"  data-action="check" type="checkbox">';
	                }
	            },{
	                orderable:      false,
	                data:           null,
	                render: function(data, type, row){
	                	return '<p style="white-space: nowrap;"><button data-key="' + row.key + '" data-file="' + row.file + '"  class="btn-delete-file btn btn-danger btn-xs"><i class="fa fa-times-circle"></i> Delete</button>'
	                	+ ' <button data-key="' + row.key + '" data-file="' + row.file + '"  class="btn-modify-file btn btn-default btn-xs"><i class="fa fa-edit"></i> Modify</button></p>';
	                }
	            },{
	    			title: 'File',
	            	data: 'file',
	            	dataSort: 0,
	            	render : function(file, type, row){

	            		var link;

	            		if(row.url_for_read){
	            			link = ' <a target="_blank" href="' + row.url_for_read + '">' + file + '</a>';
	            		}else{
	            			link = ' <span>' + file + '</span>';
	            		}

						
						if(_.endsWith(file, '.json')){
							
							if(/index-v[0-9].json/.exec(file) != null){
	            				return link;
							}
							else{
		            			var warningMetadata = '<span class="label label-warning  arrowed-in-right arrowed-in">'
								+ '<i class="ace-icon fa fa-exclamation-triangle bigger-120"></i>'
								+ ' metadata without file</span>';

		            			return warningMetadata + link;
	            			}
						}

	            		var btn = '';	            		
	            		if(row.metadata_file){
	            			btn += '<button class="btn-file-metadata btn btn-info btn-minier">Edit metadata</button>';
	            		}
	            		else{
	            			btn += '<button class="btn-file-metadata btn btn-primary btn-minier">Create metadata</button>';
	            		}

	            		return btn + link;
	            	}
	            },{
	    			title: 'Size',
	            	data: 'size_pretty',
	            	dataSort: 1,
	                visible: false,
	            	render : function(data, type, row) {
            			return '<p>' + (data||'') + '</p>';
	            	}
	            }, {
	            	title: 'Last modified',
	            	data: 'head.last_modified',
	            	type: 'date',
	                visible: false,
	        	}
	        ],  
	        lengthChange: false,
	        paging: false,
	        searching: true,
	        info: false,
	        //processing: true,
	        language: {
				//processing: '<p class="lead">Loading...</p>',
				emptyTable: ' '
			},
	        order: [[6, 'desc']]
	    });

		//The toolbar on top of the table. With the action buttons
		var htmlToolbar = '<div class="btn-group pull-left">'
		+ '<button id="btn-refresh" data-loading-text="Loading..." class="btn btn-default btn-sm" autocomplete="off"><i class="fa fa-refresh"></i> Refresh</button>'
			+ '<div class="btn-group">'
			  + '<button id="btn-action" type="button" class="btn btn-default btn-sm dropdown-toggle" data-toggle="dropdown" aria-expanded="false">'
			    + 'Bulk action <span class="ace-icon fa fa-caret-down icon-on-right"></span>'
			  + '</button>'
			  + '<ul class="dropdown-menu dropdown-default">'
			    + '<li><a href="#" data-action="delete" class="disabled-link"><i class="fa fa-times-circle"></i> Delete selected files</a></li>'
			    + '<li><a href="#" data-action="modify" class="disabled-link"><i class="fa fa-edit"></i> Move selected files</a></li>'
			  + '</ul>'
			+ '</div>'
		+ '</div>';


        htmlToolbar+= '<div class="pull-left" style="padding-left: 20px;padding-top: 4px;">'
        +'<div class="checkbox">'
          +'<label >'
            +'<input id="chk-details" type="checkbox" class="ace" autocomplete="off">'
            +'<span class="lbl"> show files details</span>'
          +'</label>'
        +'</div></div>';


	    $("div.table-toolbar").html(htmlToolbar);
	}


	function modifyFile(){
        $("#btn-modify-file-submit").button('loading');

		_.each(_filesToModify, function(file){
			var data = {
				old_key: file.key
			};

			// if(_filesToModify.length == 1){
			if(_modifyType == 'single'){
				data.new_path_with_key = $('#new-path').val()
			}
			else{
				var lastIndexSlash = file.key.lastIndexOf('/');

				if(lastIndexSlash == -1)
					data.new_path_with_key = $('#new-path').val() + file.key;
				else
					data.new_path_with_key = $('#new-path').val() + file.key.substr(lastIndexSlash);
			}

			$.ajax({
				type: "POST",
				url: "/s3/modify_file",
				data: { cp: $('#filter_content_provider').val(), param : JSON.stringify(data) },
				error: function(){
					toastr.error('An error occured while trying to modify the file "' + _filesToModify[0].file + '".');
				},
				success: function(data){
					if(data.error != null){
						toastr.error(data.error);
					}
					else{
						_runningJobs.push({
							job_id: data.job_id,
							params: data.params
						});
						toastr.info('The file "' + _filesToModify[0].file + '" is being modified.');	
					}				
				},
				complete: function(){
					$('#modal-modify-file').modal('hide');
					_runningJobs.setPollingJobsInfo(true);
					_runningJobs.refreshJobs();
				}
		    });
		});
	}


	function populateMetadaFilesAvailable(ajaxResult) {
		var metadataFilesAvailable = [];
  	_.each(ajaxResult.data, function(fileObj){

  		if(fileObj.file.indexOf('.json', fileObj.file.length - '.json'.length) !== -1){
				metadataFilesAvailable.push(fileObj);    			
  		}
			else if(fileObj.metadata_file){
				metadataFilesAvailable.push(fileObj.metadata_file);
			}
		});
	
		$('.dz-metadata').each(function(){
			var jsonKey = $(this).data('key') + '.json';

			var metadata = _.find(metadataFilesAvailable, function(fm){
				return fm.key == jsonKey;
			});

			if(metadata){
				$(this).removeClass('btn-primary').addClass('btn-info').html('Edit metadata');
			}
			else{
				$(this).removeClass('btn-info').addClass('btn-primary').html('Create metadata');
			}
		});

		_modalMetadata.setMetadataFilesAvailable(metadataFilesAvailable);
	}


    function refreshFiles(){
		_nbLoading++;

		$('table').find('.btn').attr('disabled', 'disabled');
      $("#btn-refresh").button('loading');
      _table.api().ajax.reload(function(result){
      	populateMetadaFilesAvailable(result);

      	$('#btn-action.btn-info').removeClass('btn-info').addClass('btn-default');
				_nbLoading--;
				if(_nbLoading == 0){
        	$("#btn-refresh").button('reset');
					$('table').find('.btn').removeAttr('disabled');
				}
      });
    }

	return {
		init: _init,
		refreshFiles : refreshFiles
	};
})();

/*
*
*
*
*/
var Upload = (function(){
	var _s3FormData = null;

	var _modalMetadata = null;
	var _filesDao = null;
	var _table = null;
	var _dropZone = null;
	var _pathChooser = null;

	function _init(modalMetadata, filesDao, table, pathChooser){

		_modalMetadata = modalMetadata;
		_filesDao = filesDao;
		_table = table;
		_pathChooser = pathChooser;

		try {
			_dropZone = new Dropzone("#dropzone" , {
				paramName: "file", // The name that will be used to transfer the file
				maxFilesize: 10240, // MB			
				addRemoveLinks : true,
				fallback: function(){},
				dictDefaultMessage : '<span class="bigger-150 bolder"><i class="ace-icon fa fa-caret-right red"></i> Drop files</span> to upload <span class="smaller-80 grey">(or click)</span> <br /> <i class="upload-icon ace-icon fa fa-cloud-upload blue fa-3x"></i>',
				dictResponseError: 'Error while uploading file!',
				parallelUploads: 20,

				//change the previewTemplate to use Bootstrap progress bars
				previewTemplate: '<div class="dz-preview dz-file-preview">\n  <div class="dz-details">\n    <div class="dz-filename"><span data-dz-name></span></div>\n    <div class="dz-size" data-dz-size></div>\n    <img data-dz-thumbnail />\n  </div>\n  <div class="progress progress-small progress-striped active"><div class="progress-bar progress-bar-success" data-dz-uploadprogress></div></div>\n  <div class="dz-success-mark"><span></span></div>\n  <div class="dz-error-mark"><span></span></div>\n  <div class="dz-error-message"><span data-dz-errormessage></span></div>\n</div>',

				init: function() {
					this.on("addedfile", function(file) {

				 		file.key = _s3FormData.fields.key.replace('${filename}', file.name);

						var metadata = _.find(_modalMetadata.getMetadataFilesAvailable(), function(fm){
							return fm.key == file.key + '.json';
						})

						var attrs = ' data-file="' + file.name + '" data-key="' + file.key + '" ';
						var btn = '';
						if(metadata){
							btn = '<a ' + attrs + ' class="dz-metadata btn btn-info btn-minier btn-block" style="cursor:pointer">Edit metadata</a>';				        	
						}
						else{

							attrs += ' data-size="' + file.size + '" ';
							attrs += ' data-type="' + file.type + '" ';

							btn = '<a ' + attrs + ' class="dz-metadata btn btn-primary btn-minier btn-block" style="cursor:pointer">Create metadata</a>';				        	
						}
						file.previewElement.appendChild(Dropzone.createElement(btn));

					});
					this.on("sending", function(file, xhr, formData) {
						file.s3FormData = _s3FormData;
						file.timeStart = parseInt(moment().format('X'), 10);
						_.each(_.keys(_s3FormData.fields), function(fieldKey) {
				 			formData.append(fieldKey, _s3FormData.fields[fieldKey]);
				 		});
					});
				    this.on("processing", function(file) {
						this.options.url = _s3FormData.url;
				    });
				    this.on('success', function(file){

						toastr.success('The file ' + file.name +' has been uploaded.');

				    	if(file.metadata){
				    		_modalMetadata.saveMetadata(file.metadata.key, file.metadata.metadata);
				    	}

				    	$(file.previewElement).find('.dz-remove').click(function(){
				    		_filesDao.deleteFile(file.name, file.key);
				    	});

				    	SyncServer.log('UPLOAD_FILE_SUCCESS',{
				    		file: file.name,
				    		timeSpent: (parseInt(moment().format('X'), 10) - file.timeStart) + ' seconds',
				    		formData: file.s3FormData
				    	});

				    });
				    this.on('queuecomplete', function(){
				    	if(this.files.length > 0){
				    		_table.refreshFiles();
				    	}
				    });
				    this.on('error', function(file, errorMessage, xhr){
				    	var errorMessage = errorMessage || ((xhr||{}).responseText || '');

				    	SyncServer.log('UPLOAD_FILE_ERROR',{
				    		errorMessage: errorMessage,
				    		file: file.name,
				    		timeSpent: (parseInt(moment().format('X'), 10) - file.timeStart) + ' seconds',
				    		formData: file.s3FormData
				    	});
				    	if(console){
				    		console.log(xhr);
				    	}
				    	$('#upload-errors').append('<pre>erorMessage:' + errorMessage +
				    		'<br>xhr response:' + ((xhr||{}).responseText || '')  + '</pre>');
				    	$('#upload-errors').show();
				    });
				}
			});

			$(document).on("click", '.dz-metadata', function(e) {
				var fileKey = $(this).data('key');
				var fileName = $(this).data('file');

				var options = {
					mimeType: $(this).data('type'),
					size: $(this).data('size')
				}

			    _modalMetadata.showFromDropZone(fileName, fileKey, options);

				return false;
			});

		} catch(e) {
		  alert('Sorry but you need a more recent browser to be able to upload files.');
		}
	}



	return {
		init: _init,
		getDropZone: function(){ return _dropZone; },
		fetchS3formData: function(){

			// var path = encodeURIComponent($("#input-upload-folder").val().trim());
			// $.get("/s3/get_form?path=" + path + '&cp=' + $('#filter_content_provider').val())
			// .done(function(result) {
			// 	if(result.error){
			// 		alert(result.error);
			// 		_pathChooser.rollback();
			// 	}else{
		 //    		_s3FormData = result.form;
		 //    	}
			// })
			// .error(function(){
			// 	_pathChooser.rollback();
			// });
		}
	};
})();

/*
*
*
*
*/
	var PathChooser = (function(){

		var _upload = null;

		function _init(upload){
			_upload = upload;

		    $(document).on("click", '#btn-upload-folder', function(e) {
				$(this).hide();
				var input = $("#input-upload-folder")
				var oldVal = input.val();
				input.show().focus().val('').val(oldVal).data('old-value', oldVal);
			});

		    $(document).on("keyup", '#input-upload-folder', function(e) {
		    	if(e.which === 13){ //ENTER
		    		$("#input-upload-folder").blur();
		    	}
		    	else if(e.which === 27){ //ESC
		    		$("#input-upload-folder").hide().val($("#input-upload-folder").data('old-value'));
		    		$("#btn-upload-folder").show();
				}
			});

	    $(document).on("blur", '#input-upload-folder', function(e) {
			var val = $("#input-upload-folder").hide().val().trim();
			if(val == '/' || val == ''){
				val = 'root'
			}
			else if(_.endsWith(val, '/')){
				val = val.substr(0, val.length - 1);
			}
			$("#btn-upload-folder").html(val).show();

	    	_upload.fetchS3formData();
	    });


			//apply folder value from localStorage
			
			var storage = $.localStorage;
			var filter_key = 'repo_filter_content_provider';
			if(storage.isSet(filter_key)){
				var val = storage.get(filter_key);
				if(-1 < $.inArray(val,$("#filter_content_provider > option").map(function() { return $(this).val(); }) )){
					set(val);
				}
			}

		}

		function set(newPath){
			if(newPath == '/'){
				$("#input-upload-folder").val(newPath);
				$("#btn-upload-folder").html('root')
			}
			else{
				$("#btn-upload-folder").html(newPath);

				if(_.endsWith(newPath, '/') ) {
					$("#input-upload-folder").val(newPath);
				}
				else{
					$("#input-upload-folder").val(newPath + '/');
				}
			}

	    	_upload.fetchS3formData();
		}

		return {
			init: _init,
			set: set,
			rollback: function(){
				var oldValue = $("#input-upload-folder").data('old-value');
				$("#input-upload-folder").hide().val(oldValue);
				if(oldValue == '/' || oldValue == ''){
					oldValue = 'root'
				}
				$("#btn-upload-folder").html(oldValue).show();
			}
		};
	})();


	ModalMetadata.init(Upload, FilesDao, FilesTable);
	FilesTable.init(ModalMetadata, FilesDao, RunningJobs);
	Upload.init(ModalMetadata, FilesDao, FilesTable, PathChooser);
	RunningJobs.init(FilesTable);
	PathChooser.init(Upload);
	FilesDao.init(FilesTable);


	Upload.fetchS3formData();
	RunningJobs.refreshJobs();

	$('[data-toggle="tooltip"]').tooltip();

});