"use strict";

var Page;

$(function(){
	function humanFileSize(bytes) {
    var thresh = 1024;
    if(bytes < thresh) return bytes + ' B';
    var units = ['KiB','MiB','GiB','TiB','PiB','EiB','ZiB','YiB'];
    var u = -1;
    do {
        bytes /= thresh;
        ++u;
    } while(bytes >= thresh);
    return bytes.toFixed(1)+' '+units[u];
	};

	Page = {
		cacheAnalytics: {},
		pathInBucket: '',
		files: [],
		round: function(num){
			// return Math.round(num*100)/100;
			return Math.round(num);
		},
		mediaspotLoadedOnce: false,
		cache: {},
		contentProvider: null,
		mediaspots: [],
		getClientFiles: function(client_name){
			var cacheKey = 'files_' + client_name;

			// if(Page.cache[cacheKey] == undefined){
				Page.cache[cacheKey] = _.filter(Page.files, function(f){
					return _.startsWith(f.key, Page.pathInBucket);
				});
			// }
			return Page.cache[cacheKey];
		},
		getNewFiles: function(client_name, synced_date){
			var newFiles = [];

			if(synced_date == null)
				return newFiles;

			var moment_synced_date = moment(synced_date, "YYYY-MM-DD HH:mm:ss.SSSSSSSSS ZZ");

			var clientFiles = Page.getClientFiles(client_name);

			if(moment_synced_date.isValid()){
				_.each(clientFiles, function(f){
					var moment_last_modified = moment(f.head.last_modified);				
					if(moment_last_modified.isValid() &&
						moment_synced_date < moment_last_modified){
						newFiles.push(f);
					}
				});
			}

			newFiles = _.sortBy(newFiles, function(f) {
			  return - moment(f.head.last_modified);
			});

			return newFiles;
		},
		getSyncStatus: function(client_name, synced_date){
			var cacheKey = 'repo_lastmodified_' + client_name;

			// if(Page.cache[cacheKey] == undefined){

				var clientFiles = Page.getClientFiles(client_name);

				if(clientFiles.length == 0){
					Page.cache[cacheKey] = null;
				}
				else{
					var earlyDate = _.max(clientFiles, function(f){
						return moment(f.head.last_modified);
					});
					Page.cache[cacheKey] = moment(earlyDate.head.last_modified);
				}
			// }

			if(Page.cache[cacheKey] == null)
				return true;

			if(synced_date == null)
				return false;

			var moment_synced_date = moment(synced_date, "YYYY-MM-DD HH:mm:ss.SSSSSSSSS ZZ");

			if(moment_synced_date.isValid() && Page.cache[cacheKey].isValid()){
				return Page.cache[cacheKey] <= moment_synced_date;
			}

			return '<span class="red">Error while reading the sync status</span>';
		},
		zoomedInfo: null,
		createPieChart: function(settings){			

			if(settings.chart != null)
				settings.chart.clear();

			settings.chart = AmCharts.makeChart(settings.id_selector, {
		    type: "pie",
		    theme: "light",
		    startDuration: 0,
		    pullOutDuration: 0,
    		balloonText: "[[title]]<br><b>[[value]]</b> downloads ([[percents]]%)",
		    dataProvider: settings.data,
		    valueField: settings.valueField || "downloads",
		    titleField: settings.titleField
			});
		},
		createBarChart: function(settings){

			if(settings.chart != null)
				settings.chart.clear();

			settings.balloonFunction = settings.balloonFunction || function(item, graph){
				if(item.values.value == 0)
					return '';

				return '<b>' + Math.round(item.values.value) + '</b> ' +  graph.title;
			}

			var graphs = [];

			_.each(settings.titles ,function(title){
				var titleDisplay = title;
				if(settings.titlesHash){
					var titleDisplay = settings.titlesHash[title] || title;
				}
				graphs.push({
					fillAlphas: 0.8,
					lineAlpha: 0.3,
					title: titleDisplay,
					type: 'column',
					valueField: (settings.valueField || "downloads_") + title,
			    balloonFunction: settings.balloonFunction
				});
			});

			var categoryBalloonDateFormat = "MMM DD JJ:NN";
			var minPeriod = 'hh';

			if(settings.period == 'day'){
				categoryBalloonDateFormat = "MMM DD";
				minPeriod = 'DD';
			}
			else if(settings.period == 'month'){
				categoryBalloonDateFormat = "MMM";
				minPeriod = 'MM';
			}

			settings.chart = AmCharts.makeChart(settings.id_selector, {
		    type: "serial",
		    theme: "light",
		    pathToImages: "/assets/amcharts/images/",
		    dataProvider: settings.data,
		    valueAxes: [{
	        stackType: "regular",
	        axisAlpha: 0.3,
	        gridAlpha: 0.2
		    }],
		    chartScrollbar: {
					graph: "g1",
					graphType: "column",
					scrollbarHeight: 50,
	        gridAlpha: 1,
					selectedBackgroundColor: "#888888",
					autoGridCount: true,
					color: 'black'
				},
				chartCursor: {
					fullWidth: true,
					valueLineBalloonEnabled: true,
					categoryBalloonDateFormat: categoryBalloonDateFormat
				},
		    legend: {
	        borderAlpha: 0.2,
	        equalWidths: false,
	        horizontalGap: 10,
	        markerSize: 10,
	        useGraphSettings: true,
	        valueAlign: "left",
	        valueWidth: 20,
	        valueFunction: function(item){
	        	if(item.values && item.values.percents)
	        		return Math.round(item.values.percents *10) / 10 + '%';

	        	return '';
	        }
	    	},
		    graphs: graphs,
		    categoryField: "time",
		    categoryAxis: {
	      	parseDates: true,
	      	minPeriod: minPeriod,
		    }
			},0);
		

			settings.chart.addListener("init", function(){
				if(Page.zoomedInfo != null && Page.zoomedInfo.period == settings.period){
					settings.chart.zoomToDates(Page.zoomedInfo.startDate, Page.zoomedInfo.endDate);
				}
			});

			setTimeout(function(){
				settings.chart.addListener("zoomed", function(zoomInfo){
					if(zoomInfo.startDate != undefined && zoomInfo.endDate != undefined ){
						Page.zoomedInfo = {
							period: settings.period,
							startDate: zoomInfo.startDate,
							endDate: zoomInfo.endDate
						}
					}
				});				
			},500);

			Page.chart = settings.chart;
		}
	};


	var TableTopFiles = (function(){
    var _tableTopFiles = $('#table-top-files').dataTable({
      data: [],
      columns: [
        {
            data: 'file',
            title: 'File',
            render: function(file, type, row){
            	if(!row.size){
            		return file;
            	}
            	return file + ' (' + humanFileSize(row.size) + ')';
            }
        },
        {
            data: 'downloads',
            title: 'Downloads'
        }
      ],
      lengthChange: false,
      paging: false,
      searching: false,
      info: false,
      // order: [[2, 'desc']]
      order: [[1, 'desc']],
      language: {
				emptyTable: 'No data'
			}
    });

		var _client = null;
		var _mediaspot_id = null;
		var $loader = $('#top-files .loader');


		$(document).on('change', '#top-files input[type=radio]', function(e){			
			show(_client, _mediaspot_id,  $(this).data('days'));
		});

		function processResult(result){
    	_tableTopFiles.fnClearTable();

			if(result.data.length == 0){
				return;
			}

	  	var data = _.map(result.data, function(entry){

				entry.downloads = Page.round(entry.downloads);

				var slashLastIndex = (entry.file||'').lastIndexOf('/');

				if(slashLastIndex > -1){
					entry.file = entry.file.substr(slashLastIndex+1);
				}

				return entry;
	  	});


    	_tableTopFiles.fnAddData(data);
		}

		function show(client, mediaspot_id, days){
			_client = client;
			_mediaspot_id = mediaspot_id;

			days = days || $('#top-files label.active input').data('days') || '';

			var url = '/analytics/files_distribution';
			url += '?client=' + _client;
			url += '&mediaspot_id=' + (_mediaspot_id || '');
			url += '&days=' + days;

			var resultCache = Page.cacheAnalytics[url];

			if(_.isUndefined(resultCache)){
				$loader.show();
				$.getJSON(url)
			  .done(function(result) {
			  	Page.cacheAnalytics[url] = result;
			  	processResult(result);
			  })
			  .always(function() {
					$loader.hide();
			  });
			}
			else {
		  	processResult(resultCache);
			}

		}

		return {
			show: show
		};


	})();



	var DownloadsOverTime = (function(){
		var _chart = null;
		var _client = null;
		var _mediaspot_id = null;
		var _chart_type = $('#global-chart-container .chart-type label.active input').val();
		var _chart_period = $('#global-chart-container .chart-period label.active input').val();
		var $loader = $('#global-chart-container .loader');		
		var $div = $('#global-chart-container');
		var _displayed = false;

		$(document).on('change', '#global-chart-container .chart-type input[type=radio]', function(e){
			_chart_type = this.value;
			updateChart();
		});
		$(document).on('change', '#global-chart-container .chart-period input[type=radio]', function(e){
			_chart_period = this.value;
			updateChart();
		});

		$('[href="#tab-analytics"]').on('shown.bs.tab', function () {
			if(_displayed == false){
				updateChart();
			}
		});

		function toggleMediaspotsOption(toShow){
			if(toShow){
				$('#global-chart-container .chart-type input[value="mediaspot"]').closest('label').show();
			}
			else{
				if(_chart_type == 'mediaspot'){
					$('#global-chart-container .chart-type label input[value="file"]').click();
				}
				$('#global-chart-container .chart-type input[value="mediaspot"]').closest('label').hide();
			}
		}

		function getHashTitlesPerTypeofChart(typeOfChart, titles){
			if(typeOfChart== 'file'){
		  	return _.reduce(titles, function(hash, file){

					var slashLastIndex = (file||'').lastIndexOf('/');

					if(slashLastIndex > -1){
						hash[file] = file.substr(slashLastIndex+1);
					}else{
						hash[file] = file;
					}
					return hash;

		  	}, {});
			}
			
			if(typeOfChart == 'mediaspot' || typeOfChart == 'failed-downloads'){
				return Page.hashMediaspotNames
			}

			if(typeOfChart == 'content-type'){
				return _.reduce(titles, function(hash, file_type){
		  		if(file_type == null){
		  			hash[file_type + ''] = 'No Type';
		  		}
		  		else{
		  			hash[file_type] = file_type
		  		}
					return hash;
		  	}, {});
			}
		}

		function populateMissingData(response){

			// if(response.args.period == 'day'){

			// }
		  		// var after = {
	  			// 	time: (new Date()).toISOString()
	  			// };

	  			// _.each(response.result.titles, function(t){
	  			// 	//after['downloads_' + t] = 0;
	  			// });

	  			// response.result.data.push(after);

			return;
	  			var before = {
	  				time: moment("2015-02-02").toISOString()
	  			};
		  		var after = {
	  				time: (new Date()).toISOString()
	  			};

	  			_.each(response.result.titles, function(t){
	  				before['downloads_' + t] = 0;
	  				after['downloads_' + t] = 0;
	  			});

	  			response.result.data.unshift(before);
	  			response.result.data.push(after);
		}

		function drawChart(response){

	  	if($('#tab-analytics').is(':visible') == false){
	  		return;
	  	}

  		_displayed = true;

	  	if(response.result.data.length == 0 || response.result.titles.length == 0){
  			$('#global-chart-no-data').show();
  			$('#global-chart').hide();
  			return;
	  	}

			$('#global-chart-no-data').hide();
			$('#global-chart').show();

			var valueField = 'downloads_';

			if(response.args.type == 'failed-downloads')
				valueField = 'num_failures_';

			Page.createBarChart({
				data: response.result.data,
				titles: response.result.titles,
				titlesHash: getHashTitlesPerTypeofChart(response.args.type, response.result.titles),
				chart: _chart,
				id_selector: 'global-chart',
				period: response.args.period,
				valueField: valueField
			});

		}

		function updateChart(){
			var url = '/analytics/downloads';
			url += '?client=' + _client;
			url += '&mediaspot_id=' + (_mediaspot_id || '');
			url += '&period=' + _chart_period;
			url += '&type=' + _chart_type;

			_displayed = false;

			var resultCache = Page.cacheAnalytics[url];

			if(_.isUndefined(resultCache)){	

			$('#global-chart').html('');
				$loader.show();
				$.getJSON(url)
			  .done(function(response) {

	  			populateMissingData(response);

			  	Page.cacheAnalytics[url] = response;
			  	drawChart(response);
			  })
			  .always(function() {
					$loader.hide();
			  });
			}
			else{
		  	drawChart(resultCache);
			}
		}

		function show(client, mediaspot_id){
			_client = client;
			_mediaspot_id = mediaspot_id || '';
			toggleMediaspotsOption(!mediaspot_id);
			$div.show();
			updateChart();
		}


		return {
			show: show,
			hide: function(){
				$div.hide();
			}
		};

	})();



	var DivDetails =(function(){

		var $div = $('#mediaspot-detail');

		var _mediaspot = null;

		// var _chartsDrawn = false;

		function _showAggregateAnalitycs(client){

			window.location.hash = '';

			if(Page.mediaspots.length == 0){
				$div.hide();
				return;
			}

			_mediaspot = null;

  		$('[href="#tab-analytics"]').tab('show')
			$div.find('.mediaspot-tabs').hide();

			var title = '';
			if($('#select_content_provider option').length > 1){
				title = 'Aggregated analytics for <b>' + Page.contentProvider.displayName + '</b>';
			}
			else{
				title = 'Aggregated analytics';
			}
			$div.find('h4').html(title);
			$div.show();


			DownloadsOverTime.show(client);
			TableTopFiles.show(client);
		}

		// $('[href="#tab-analytics"]').on('shown.bs.tab', function () {
		// 	if(_chartsDrawn == false && _mediaspot != null){
		// 		TableTopFiles.show(_mediaspot.client_name, _mediaspot.mediaspot_id);
		// 		ChartDeviceTypes.show(_mediaspot.client_name, _mediaspot.mediaspot_id);
		// 	}
		// })

		function _showMediaspot(mediaspot){	

			_mediaspot = mediaspot;

      window.location.hash = (_mediaspot.mediaspot_name || _mediaspot.mediaspot_id);

 			$div.find('.mediaspot-tabs').show();

 			if(_mediaspot.analytics_last_made_time_ago)
				$('[href="#tab-analytics"]').html('Analytics (updated ' + _mediaspot.analytics_last_made_time_ago + ')');
			else
				$('[href="#tab-analytics"]').html('Analytics');

			var syncInfo = '';
  		if(mediaspot.sync_error === true){
  			syncInfo = '<i class="fa fa-exclamation-triangle red"></i> ';
  		}
  		else if(mediaspot.online == false && mediaspot.syncing === true){
  			syncInfo = '<i class="fa fa-exclamation-triangle orange"></i> ';
  		}
  		else if(mediaspot.syncing === true){
  			syncInfo = '<i class="fa fa-cloud-download orange"></i> ';
  		}

  		$('#sync-info').html(syncInfo);


			$div.find('h4').html('Mediaspot ' + (_mediaspot.mediaspot_name || _mediaspot.mediaspot_id));
			$div.show();

			$('#sync-log').html(_mediaspot.sync_log);
			$('#contents-tree').html(_mediaspot.contents_tree);

			var index_json = _mediaspot.index_json;

			try{
				index_json = JSON.stringify(JSON.parse(_mediaspot.index_json), null, 2);
			}
			catch(ex){}

			$('#index-json').html(index_json);


			DownloadsOverTime.show(_mediaspot.client_name, _mediaspot.mediaspot_id);
			TableTopFiles.show(_mediaspot.client_name, _mediaspot.mediaspot_id);

			// if($('[href="#tab-analytics"]').closest('li').hasClass('active')){
			// 	_chartsDrawn = true;
			// 	TableTopFiles.show(_mediaspot.client_name, _mediaspot.mediaspot_id);
			// 	ChartDeviceTypes.show(_mediaspot.client_name, _mediaspot.mediaspot_id);
			// }
			// else{
			// 	_chartsDrawn = false;				
			// }
		}


		return {
			showMediaspot: _showMediaspot,
			showAggregateAnalitycs: _showAggregateAnalitycs,
			hide: function(){
				$div.hide();
			},
			getMediaspot: function(){
				return _mediaspot;
			}
		}
	})();

	var Table = (function(){

		var _datatable;

		function _init(){
			initTable();
			initEvents();
		}


		function initTable(){
			_datatable = $('#mediaspots-table').dataTable({
	    	data: Page.mediaspots,
	    	columns: [
      		{ data: 'online', visible: false },
      		{ data: 'download_enabled', visible: false },
      		{
    				title: '<i id="title-icon-selected" class="fa fa-square-o fa-lg" data-selected="false"></i>',
          	orderable: false,
      			data: 'selected',
      			render: function(selected){
      				if(selected){
      					return '<i class="fa fa-check-square-o fa-lg icon-selected"></i>';
      				}
      				else{
      					return '<i class="fa fa-square-o fa-lg icon-selected"></i>';
      				}
      			}
      		},
          {
          	title: 'Mediaspot',
          	render: function(undfnd, type, row){
          		var loadingImg = '';
          		if(row.online && (row.isBusy === true || row.syncing === true)){	
          			loadingImg = ' <img width="15" height="15" src="/assets/loader.gif" >';
          		}

          		return (row.mediaspot_name || row.mediaspot_id) + loadingImg;
          	}
          },
          {
          	title: 'Online status',
          	data: 'online',
          	dataSort: 0,
          	render: function(online){
							if(online){
								return '<i class="fa fa-circle" style="color:#0C0"></i> online';
							}
							else{
								return '<i class="fa fa-circle" style="color:red"></i> offline';
							}
        		}
          },
          {
          	title: 'Download enabled',
          	data: 'download_enabled',
          	dataSort: 1,
          	render: function(download_enabled){

          		return download_enabled === true ? '<div class="badge badge-info">ON</div>'
          		:'<div class="badge badge-grey">OFF</div>';
          	}
          },
          {
          	title: 'Synchronization status',
          	data: 'sync_status',
          	render: function(sync_status, type, row){

          		var info_sync_status = '';

          		if(row.sync_error === true){
          			info_sync_status = '<b class="red"><i class="fa fa-exclamation-triangle"></i> An error happened during the last sync</b>';
          		}
          		else if(row.online == false && row.syncing === true){
          			info_sync_status = '<p class="orange"><i class="fa fa-exclamation-triangle"></i> The mediaspot went offline before finishing the sync</p>';
          		}
          		else if(row.syncing === true){
          			info_sync_status = '<i class="fa fa-cloud-download orange"></i> Syncing...';
          		}
          		else if(sync_status == null){
          			info_sync_status = 'Loading...';
          		}
          		else if (sync_status === true){
          			info_sync_status = '<i class="fa fa-check-circle" style="color:blue"></i> synced';
          		}
          		else if(sync_status == false){

								info_sync_status = '<i class="fa fa-times-circle" style="color:orange"></i>';

	          		if(row.new_files && row.new_files.length > 0){

	          			var files_names = _.map(row.new_files, function(f){

	          				return f.key.substr(_.lastIndexOf(f.key, '/') + 1);
	          			});

	          			var tooltip_title = 'new files:<br>';

	          			if(files_names.length > 3){
	          				tooltip_title += files_names.slice(0, 3).join('<br>');
	          				tooltip_title += '<br>and '  + (files_names.length - 3) + ' more file' + (files_names.length==4?'':'s')  + ' ...';
	          			}
	          			else{
	          				tooltip_title += files_names.join('<br>')
	          			}
 
	          			info_sync_status += ' <span data-toggle="tooltip" data-placement="bottom" data-html="true" title="' + tooltip_title + '" style="text-decoration:underline;cursor:default;">out of sync</span>';
						      setTimeout(function(){
						      	$('[data-toggle="tooltip"]').tooltip();
						      }, 100);
	          		}
	          		else{
	          			info_sync_status += ' out of sync';
	          		}
          			 
          		}

          		return info_sync_status;
        		}
          }],
	        lengthChange: false,
	        paging: false,
	        searching: false,
	        info: false,
	        processing: true,
	        order: [[3, 'asc']],
	        language: {
						processing: '<p class="lead">Loading...</p>',
						emptyTable: ' '
					}
		    });
		}

		function refreshTable(mediaspot_to_select){

			$('#title-icon-selected')
				.removeClass('fa-check-square-o')
				.addClass('fa-square-o')
				.data('selected', false);

			var client = $("#select_content_provider").val();
			var displayName = $("#select_content_provider option:selected").text();

      $("#btn-refresh").button('loading');

			$.getJSON('/mediaspots/get_mediaspots?client=' + client)
			.done(function(result){

				Page.pathInBucket = result.path_in_bucket;

				Page.cacheAnalytics = {};

        var checkedMediaspots = _.filter(Page.mediaspots,function(m){ return m.selected == true});
        var mediaspotInDetails = DivDetails.getMediaspot();

        if(result.mediaspots.length == 0){
        	$('#msg-no-mediaspots').show();
        }
        else{        	
        	$('#msg-no-mediaspots').hide();
        }

				Page.mediaspots = result.mediaspots;

		  	Page.hashMediaspotNames = _.reduce(Page.mediaspots, function(hash, mediaspot){
		  		hash[mediaspot.mediaspot_id] = mediaspot.mediaspot_name;
		  		return hash;
		  	}, {});

        Page.contentProvider = {};
        Page.contentProvider.clientName = client;
        Page.contentProvider.displayName = displayName;

        // $('#debug-analytics').html('<pre>' + JSON.stringify(Page, null, 2) + '</pre>');

        $("#btn-refresh").button('reset');
      	_datatable.fnClearTable();

      	if(Page.mediaspots.length > 0){
          	_datatable.fnAddData(Page.mediaspots);
      	}

      	if(mediaspot_to_select){
      		for(var i = 0; i < Page.mediaspots.length; i++){
	        	var row = _datatable.api().rows(i);
	        	var data = row.data()[0];

	        	if(data.mediaspot_id == mediaspot_to_select || data.mediaspot_name == mediaspot_to_select){
							data.selected = true;
							var $tr = $(row.nodes());
							$tr.addClass('info');
							$tr.find('.icon-selected').removeClass('fa-square-o').addClass('fa-check-square-o');
        			DivDetails.showMediaspot(data);
        			break;
	        	}
	        }
      	}
      	else{
	      	var isDivDetailsShowned = false;

	        for(var i = 0; i< Page.mediaspots.length; i++){
	        	var row = _datatable.api().rows(i);
	        	var data = row.data()[0];
						var checkedMediaspot = _.find(checkedMediaspots, {
							'mediaspot_id': data.mediaspot_id,
							'client_number': data.client_number
						});
						if(checkedMediaspot){						
							data.selected = true;
							var $tr = $(row.nodes());
							$tr.addClass('info');
							$tr.find('.icon-selected').removeClass('fa-square-o').addClass('fa-check-square-o');
						}

						if(mediaspotInDetails && data.mediaspot_id ===  mediaspotInDetails.mediaspot_id
							&& data.client_number === mediaspotInDetails.client_number){
		        			DivDetails.showMediaspot(data);
		        			isDivDetailsShowned = true;
						}
	        }

	        if(isDivDetailsShowned == false){
	        	DivDetails.showAggregateAnalitycs(client);
	        }
      	}


        activateCheckAll();
				activateActionLinks();
      	Tasks.getTasks();

				// if(Page.mediaspotLoadedOnce){
				// 	updateSyncStatus();
				// }
				// else{
        	Repo.fetchFiles();
				// }

				Page.mediaspotLoadedOnce = true;
      });
		}

		function activateActionLinks(){
			if(_.some(Page.mediaspots, 'selected')){
				$('#lnk-sync').closest('li').removeClass('disabled');
				$('#lnk-make-analytics').closest('li').removeClass('disabled');
				if(_.some(Page.mediaspots, function(m){ return m.selected && m.download_enabled !== true})){
					$('#lnk-download-on').closest('li').removeClass('disabled');
				}
				else{
					$('#lnk-download-on').closest('li').addClass('disabled');
				}
				if(_.some(Page.mediaspots, function(m){ return m.selected && m.download_enabled == true})){
					$('#lnk-download-off').closest('li').removeClass('disabled');
				}
				else{
					$('#lnk-download-off').closest('li').addClass('disabled');
				}
			}
			else{
				$('#lnk-actions li').addClass('disabled');
			}
		}

		function activateCheckAll(){
       		if (_.every(Page.mediaspots, function(m){ return m.selected == false})){
				$('#title-icon-selected')
					.removeClass('fa-check-square-o')
					.addClass('fa-square-o')
					.data('selected', false);
			}
       		else if(_.every(Page.mediaspots, function(m){ return m.selected})){
				$('#title-icon-selected')
					.removeClass('fa-square-o')
					.addClass('fa-check-square-o')
					.data('selected', true);
       		}
		}

		function setDownloadEnabled(onOff){

			_.each(Page.mediaspots, function(m){
				if(m.selected === true && m.download_enabled !== onOff){
			        var url = '/mediaspots/set_client_parameter?'
			        + 'device-id=' + m.mediaspot_id
			        + '&client-number=' + m.client_number
			        + '&parameter-name=' + 'DownloadEnabled'
			        + '&parameter-value=' + onOff;
			        
			        Tasks.submitTask(url, onOff ? 'DownloadEnabled set to On': 'DownloadEnabled set to Off');
				}
			});

		}

		function syncNow(){
			_.each(Page.mediaspots, function(m){
				if(m.selected === true) {
			        var url = '/mediaspots/set_client_parameter?'
			        + 'device-id=' + m.mediaspot_id
			        + '&client-number=' + m.client_number
			        + '&parameter-name=' + 'SyncNow'
			        + '&parameter-value=' + 'true';
			        
			        Tasks.submitTask(url, 'Sync started');
				}
			});
		}

		function makeAnalyticsNow(){
			_.each(Page.mediaspots, function(m){
				if(m.selected === true) {
			        var url = '/mediaspots/set_client_parameter?'
			        + 'device-id=' + m.mediaspot_id
			        + '&client-number=' + m.client_number
			        + '&parameter-name=' + 'MakeAnalyticsNow'
			        + '&parameter-value=' + 'true';
			        
			        Tasks.submitTask(url, 'The analytics will be updated in about one minute');
				}
			});
		}

		function initEvents(){

			$(document).on('click', '#lnk-download-on', function(e){
				setDownloadEnabled(true);
			});

			$(document).on('click', '#lnk-download-off', function(e){
				setDownloadEnabled(false);
			});

			$(document).on('click', '#lnk-sync', function(e){
				syncNow();
			});

			$(document).on('click', '#lnk-make-analytics', function(e){
				makeAnalyticsNow();
			});

			//click on the checkbox to select all the lines
			$(document).on('click', '#title-icon-selected', function(e){
				if($(this).data('selected')){
					$(this).data('selected', false);
					$(this).removeClass('fa-check-square-o')
						.addClass('fa-square-o');
					$('#mediaspots-table tr').removeClass('info');
					$('#mediaspots-table tbody .icon-selected')
						.removeClass('fa-check-square-o')
						.addClass('fa-square-o');
	       			_.each(Page.mediaspots, function(m){
	       				m.selected = false;
	       			});
				}
				else {
					$(this).data('selected', true);
					$(this).removeClass('fa-square-o')
						.addClass('fa-check-square-o');
					$('#mediaspots-table tr').addClass('info');
					$('#mediaspots-table tbody .icon-selected')
						.removeClass('fa-square-o')
						.addClass('fa-check-square-o');
	       			_.each(Page.mediaspots, function(m){
	       				m.selected = true;
	       			});
				}
				activateActionLinks();
			});


			//select a line
			$('#mediaspots-table tbody').on('click', 'tr', function(e){
				var $tr = $(this).closest('tr');
	       		var mediaspot = _datatable.api().row($tr[0]).data();
	       		if(!mediaspot)
	       			return;

				var fromCheckbox = $(e.target).is('.icon-selected') || $(e.target).find('.icon-selected').length > 0;

				//if we uncheck a mediaspot
				// if(fromCheckbox && mediaspot.selected){
				if(mediaspot.selected){
					$tr.find('.icon-selected')
						.removeClass('fa-check-square-o')
						.addClass('fa-square-o');
					$tr.removeClass('info');
					mediaspot.selected = false;
					DivDetails.hide();
        	DivDetails.showAggregateAnalitycs(Page.contentProvider.clientName);
				}
				else {

					//if we selected the line (not the checkbox)
					if(fromCheckbox == false){
						$('#mediaspots-table tbody tr').removeClass('info');
						$('#mediaspots-table tbody .icon-selected')
							.removeClass('fa-check-square-o')
							.addClass('fa-square-o');

		       			_.each(Page.mediaspots, function(m){
		       				m.selected = false;
		       			});
					}

					$tr.addClass('info');
					$tr.find('.icon-selected').removeClass('fa-square-o').addClass('fa-check-square-o');

	       			mediaspot.selected = true;
	       			DivDetails.showMediaspot(mediaspot);
				}

				activateCheckAll();

				activateActionLinks();
			});

		    $(document).on("click", "#btn-refresh", function() {
		        refreshTable();
		        return false;
		    });
		}


		function updateSyncStatus(){
			for(var i = 0, l = _datatable.api().data().length; i<=l; i++){
				var row = _datatable.api().row(i).data();
				if(row && row.sync_error === false && row.syncing === false){
					row.sync_status = Page.getSyncStatus(row.client_name, row.synced_date);

					if(row.sync_status == false && row.synced_date != null ){
						var new_files = Page.getNewFiles(row.client_name, row.synced_date);
						if(new_files && new_files.length > 0){
							row.new_files = new_files;
						}
					}

					_datatable.api().row(i).data(row);
				}
			}
		}

		function updateTasksStatus(tasksClients){

			for(var i = 0, l = _datatable.api().data().length; i<=l; i++){
				var row = _datatable.api().row(i).data();
				if(row){

					// row.isBusy = false;

					// _.each(tasksClients, function(client){
					// 	if(row.mediaspot_id === client.mediaspot_id && row.client_number === client.client_number){							
					// 		if(client.tasks.length > 0){
					// 			row.isBusy = true;				
					// 		}
					// 	}
					// })

					row.isBusy = _.any(tasksClients, function(client){
						return row.mediaspot_id === client.mediaspot_id &&
							row.client_number === client.client_number &&
							client.tasks.length > 0
					})

					_datatable.api().row(i).data(row);

				}
			}
		}

		return {
			init: _init,
			updateSyncStatus: updateSyncStatus,
			updateTasksStatus: updateTasksStatus,
			refreshTable: refreshTable,
			emptyTable: function(){				
	      _datatable.fnClearTable();
			}
		};
	})();


	var Tasks = (function(){
		var _tasks = [];

		function _init(){
			setupWebSocket();
		}

		function setupWebSocket(){

			Page.websocket_dispatcher = new WebSocketRails(window.location.host + '/websocket');

      Page.websocket_dispatcher.bind('connection_closed', function() {
          console.log('websocket connection closed. Attempting to reconect in 5 seconds');
          setTimeout(setupWebSocket, 5000);
      })


			var channel = Page.websocket_dispatcher.subscribe('tr069');

			channel.bind('tasks_inserts', function(tasks) {

			  tasks = JSON.parse(tasks);

			  _.each(tasks, function(task){

			  	var client = _.find(_tasks, function(c){
			  		if(c.mediaspot_id == task.device){

			  			if(task.objectName && task.objectName.indexOf('.Clients.' + c.client_number) > -1){
			  				return true;
			  			}

			  			if(task.parameterValues && task.parameterValues[0] &&
			  				task.parameterValues[0][0].indexOf('.Clients.' + c.client_number) > -1){
			  				return true;
			  			}
			  		}
			  		return false;
			  	});

			  	if(client){
			      if(!_.find(client.tasks, { _id: task._id})){
			          client.tasks.push(task);
			      }
			  	}

			  });

			  Table.updateTasksStatus(_tasks);
			});

			channel.bind('tasks_remove', function(task) {

				task = JSON.parse(task);

				var toReload = false;

				_.each(_tasks, function(client){

					var newTasks = _.reject(client.tasks, { _id: task._id });

					if(newTasks.length == 0 && client.tasks.length == 1){
						toReload = true;
					}

					client.tasks = newTasks;
				})

			  Table.updateTasksStatus(_tasks);

			  if(toReload)
			  	Table.refreshTable();

			});

			Page.channel = channel;
		}

		function getTasks(){
			var clients = _.map(Page.mediaspots, function(m){
				return {
					mediaspot_id: m.mediaspot_id,
					client_number: m.client_number
				}
			});

			if(clients.length == 0){
				_tasks = [];
				return;
			}

			$.ajax({
				type: 'POST',
				url: 'mediaspots/get_task_queue',
				data: JSON.stringify({clients: clients}),
				contentType: "application/json; charset=utf-8",
				dataType: "json",
				success: function (result) {

          _tasks = result.clients;

					Table.updateTasksStatus(_tasks);

				}
			});

		}


    //submit a task to the mediaspot
    function submitTask(url, message) {

      // $('#progress-bar-client').show();
      // disableButtons();

      $.get(url, function(result){
        // $('#progress-bar-client').hide();
        // enableButtons();
        if(result.sync_already_running){
            toastr.warning('Task already processing');
        }
        else if(result.sync_already_in_queue){
            toastr.warning('Task already in the queue');
        }
        else{
        	toastr.info(message || 'Task added to the queue.');
        }


        // lastTasksAmount[selectedDevice.details['_id']] = 1;
        // refreshTaskQueue(callback);
      });
    }

		return {
			submitTask: submitTask,
			getTasks: getTasks,
			init: _init
		};
	})();


	var Repo = (function(){

		var _table;

		function _init(table){
			_table = table;
			// setTimeout(fetchFiles, 0);
		}

		function fetchFiles(){
			var clients = _.uniq(_.pluck(Page.mediaspots, 'client_name'));

			var url = '/s3/get_files_with_last_modified_date?client=' + Page.contentProvider.clientName;

			$.getJSON(url)
			.done(function(result){
				Page.files = _.filter(result.data, function(f){
					return _.contains(f.key, '.staging/') == false && _.endsWith(f.key, '/') == false;
				});

				_table.updateSyncStatus();
			});

		}

		return {
			init: _init,
			fetchFiles: fetchFiles
		}
	})();

	//apply content_provider value from localStorage	
	var storage = $.localStorage;
	var select_key = 'mediaspot_select_content_provider';
	if(storage.isSet(select_key)){
		var val = storage.get(select_key);
		if(-1 < $.inArray(val,$("#select_content_provider > option").map(function() { return $(this).val(); }) )){
			$('#select_content_provider').val(val);
		}
	}


	//apply each period selector value from localStorage	
	$(".period-selector").each(function(){
		var val = null;
		if(storage.isSet($(this).data('localstorage-key')))
			val = storage.get($(this).data('localstorage-key'));

		if(val != null){
			var dataKey = $(this).data('data');
			var labels = $(this).find('label');

			$(this).find('input').each(function(){

				if($(this).data(dataKey) == val){
					$(this).prop("checked", true)

					labels.removeClass('active');

					$(this).closest('label').addClass('active');
				}
			})
		}
	});


	var mediaspot_to_select = undefined;
	//automatically select a mediaspot if it's in the url
	if(window.location.hash.split('#').length == 2){
	  mediaspot_to_select = window.location.hash.split('#')[1];
	}


	$(document).on("change", "#select_content_provider", function() {
		Table.emptyTable();	
		DivDetails.hide();
		Table.refreshTable();
    storage.set(select_key, $('#select_content_provider').val())
	});


	Tasks.init();
	Table.init();
	Repo.init(Table);
	Table.refreshTable(mediaspot_to_select);


  $('[data-toggle="tooltip"]').tooltip();

});