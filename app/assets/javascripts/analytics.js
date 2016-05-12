"use strict";

$(function(){
	SyncServer.MediaspotsAnalytics = (function(){

		var _toExclude = ['.json', '.png', '.jpg'];

		var _topPerHours = [null, 24, 168, 720];

		function parseJson(analytics){

			var result = null;

			if((analytics || '').trim() === '')
				return result;

			try{
				result = JSON.parse(analytics);
			}
			catch(e){
				if(console){
					console.log('error while parsing this string :');
					console.log(analytics);
				}
			}

			return result;
		}


		function prepare(mediaspots){
			var config = {
				minHour: null,
			  maxHour: null,
			  files: []
			};

			_.each(mediaspots, function(mediaspot){

				var filesToSave = [];

				_.each(mediaspot.analytics.files, function(file){

					if(_.any(_toExclude, function(extension){ return _.endsWith(file.filename, extension)})){
						return;
					}

					file.size = parseInt(file.size, 10) || null;

					var existingFile = _.find(config.files, function(resultFile){
						return resultFile.filename === file.filename
							&& resultFile.size === file.size;
					});

					if(!existingFile){
						existingFile = {
							filename: file.filename,
							size: file.size,
							totalBytes: 0,
							totalDownloads: 0
						}
						config.files.push(existingFile);
					}

					_.each(file.downloadedbytes, function(time){
						time.bytes = parseInt(time.bytes, 10) || null;
						time.hour = parseInt(time.hour, 10) || null;

						time.downloads = 0;

						if(file.size != null){
							time.downloads = time.bytes / file.size;
							existingFile.totalDownloads += time.downloads;
						}

						if(time.bytes != null){
							existingFile.totalBytes += time.bytes;
						}

						if(config.minHour === null || time.hour < config.minHour){
							config.minHour = time.hour;
						}
						if(config.maxHour === null || time.hour > config.maxHour){
							config.maxHour = time.hour;
						}
					});

					filesToSave.push(file);
				});
				
				mediaspot.analytics.files = filesToSave;
				
			});

			if(config.minHour !== null){
				config.minHour -= 2;
				config.maxHour += 2;
			}

			return config;
		}


		function calculateTopFiles(mediaspots, hours){

			var aggregatedTopFiles = [];
			var aggregatedTopMediaspots = [];

			_.each(mediaspots, function(mediaspot){

				var mediaspotData = {
					name: mediaspot.mediaspot_name,
					id: mediaspot.mediaspot_id,
					color: SyncServer.getChartColorByKey('mediaspot', mediaspot.mediaspot_id),
					totalBytes: 0,
					downloads: 0
				}

				var topFiles = [];

				_.each(mediaspot.analytics.files, function(file){

					var hourLimit = 0;
					if(hours){
						var hourNow = Math.floor(parseInt(moment().format('X')) / 3600);
						hourLimit = hourNow - hours;
					}

					var totalBytes = _.reduce(file.downloadedbytes, function(result, timeBytes){
						if(timeBytes.hour >= hourLimit) {
							return result + timeBytes.bytes;
						}
						return result;
					}, 0);

					if(totalBytes > 0){
						var downloads =  null;
						if(file.size !== null){
							downloads =  totalBytes / file.size;
							// downloads = Math.round(downloads*100)/100;
							downloads = downloads;
						}

						topFiles.push({
							file: file.filename,
							size: file.size,
							totalBytes: totalBytes,
							downloads: downloads
						});

						mediaspotData.totalBytes += totalBytes;
						mediaspotData.downloads += downloads;

						var existingAgg = _.find(aggregatedTopFiles, function(aggTopFile){
							return aggTopFile.filename == file.filename && aggTopFile.size == file.size;
						})

						if(existingAgg){
							existingAgg.totalBytes += totalBytes;
						}
						else{
							aggregatedTopFiles.push({
								file: file.filename,
								size: file.size,
								totalBytes: totalBytes
							});
						}
					}
				});

				mediaspot['topFiles' + (hours || '')] = topFiles;

				aggregatedTopMediaspots.push(mediaspotData);

			});

			_.each(aggregatedTopFiles, function(file){
				var downloads = 0;			
				if(file.size !== null){
					downloads =  file.totalBytes / file.size;
					// downloads = Math.round(downloads*100)/100;
					downloads = downloads;
				}
				file.downloads = downloads;
			})

			var res = {};
			res['topFiles' + (hours || '')] = aggregatedTopFiles;
			res['topMediaspots' + (hours || '')] = aggregatedTopMediaspots;

			return res;
		}


		function calculateDevicesAnalitycs(mediaspots){

			var aggregated = [];

			_.each(mediaspots, function(mediaspot){

				mediaspot.chartDownloadsPerDevice = [];

				_.each(mediaspot.analytics.devicetypes, function(v , k){
					v = parseInt(v, 10);
					if(v > 0){

						var device ={
							devicetype: k,
							downloads: v,
							color: SyncServer.getChartColorByKey('device', k)
						};

						mediaspot.chartDownloadsPerDevice.push(device);

						var existingAggDevice = _.find(aggregated, function(aggDevice){
							return aggDevice.devicetype == device.devicetype;
						})

						if(existingAggDevice){
							existingAggDevice.downloads += device.downloads;
						}
						else{
							aggregated.push(_.clone(device));
						}
					}
				});

			});

			return aggregated;
		}


		function calculateFilesDownloadsData(mediaspots, config){

			var aggregated = {
				chartData: []
			}

			var times = [];

			if(config.minHour !== null){
				for(var hour = config.minHour; hour <= config.maxHour; hour++){
					var time = {
						// date: moment(hour * 3600,'X').format(),
						date: moment(hour * 3600,'X').toDate(),
						hour: hour
					}
					times.push(time);
					aggregated.chartData.push(_.clone(time));
				}
			}

			_.each(mediaspots, function(mediaspot){

				var total = {
					filename: 'All files',
					size:0,
					downloads: 0,
					chartData: []
				}
				_.each(times, function(time){
					total.chartData.push({
						date: time.date,
						hour: time.hour,
						downloads: 0
					});
				});

				mediaspot.chartFileDownloads = [];

				_.each(config.files, function(file){

					var existingFile = _.find(mediaspot.analytics.files, function(f){
						return f.filename == file.filename && f.size == file.size;
					});

					if(existingFile){

						var fileData = _.clone(file);
						fileData.chartData = [];
						fileData.downloads = 0;

						mediaspot.chartFileDownloads.push(fileData);

						var i = 0;
						_.each(times, function(time){

							var existingTime = _.find(existingFile.downloadedbytes, function(t){
								return t.hour == time.hour;
							});

							var downloads = 0;
							if(existingTime){
								downloads = existingTime.downloads;
							}

							fileData.chartData.push({
								hour: time.hour,
								date: time.date,
								downloads: downloads
							});

							var totalTime = total.chartData[i];

							if((totalTime||{}).hour != time.hour){
								if(console)
									console.log('error calculating total');

								totalTime = _.find(total.chartData, function(t){ return t.hour == time.hour})
							}

							totalTime.downloads += downloads;

							aggregated.chartData[i]['downloads_' + mediaspot.mediaspot_id] =
							 (aggregated.chartData[i]['downloads_' + mediaspot.mediaspot_id] || 0) + downloads;

							aggregated.chartData[i]['downloads'] = (aggregated.chartData[i]['downloads'] || 0) + downloads;

							i++;
						});
					}
				});

				total.downloads = _.reduce(total.chartData, function(sum, time){					
					return sum + time.downloads;
				},0)

				mediaspot.chartFileDownloads.push(total);
				
				mediaspot.chartFileDownloads = _.sortBy(mediaspot.chartFileDownloads, function(file){
					return - (file.downloads || 0);
				});
			});

			if(mediaspots.length == 0)
				return [];

			return aggregated.chartData;
		}

		function calculateAggregatedPerPeriod(dataPerHour, funcIsDiffPeriod){
			var dataPerAggregated = [];

			var onePeriodData = null;

			var previousPeriodDate = null;
			_.each(dataPerHour, function(timeHour){

				if(funcIsDiffPeriod(previousPeriodDate, timeHour.date)){
					if(onePeriodData != null){
						dataPerAggregated.push(onePeriodData);
					}

					onePeriodData = {
						date: timeHour.date
					};
				}

				_.each(_.keys(timeHour), function(key){
					if(_.startsWith(key, 'downloads')){
						onePeriodData[key] = (onePeriodData[key]||0) + timeHour[key];
					}
				});

				previousPeriodDate = timeHour.date;
			})

			if(onePeriodData != null){
				dataPerAggregated.push(onePeriodData);
			}

			return dataPerAggregated;
		}


		function generateAnalytics(mediaspots){

			var aggregatedAnalytics = {};

			_.each(mediaspots, function(m){
				m.serializedAnalytics = m.analytics;
				m.analytics = parseJson(m.analytics);
			})

			var goodMediaspots = _.filter(mediaspots, function(mediaspot){
				return mediaspot.analytics != null;
			})

			goodMediaspots = _.sortBy(goodMediaspots, 'mediaspot_name');

			var config = prepare(goodMediaspots);

			aggregatedAnalytics.chartDownloadsPerMediaspot = {};


			aggregatedAnalytics.chartDownloadsPerMediaspot.hh = calculateFilesDownloadsData(goodMediaspots, config);

			//aggregated data per day
			aggregatedAnalytics.chartDownloadsPerMediaspot.DD =
			calculateAggregatedPerPeriod(aggregatedAnalytics.chartDownloadsPerMediaspot.hh, function(prevPeriodDate, currentPeriodDate){
				return prevPeriodDate == null || moment(prevPeriodDate).day() !== moment(currentPeriodDate).day();
			});

			//aggregated data per week
			aggregatedAnalytics.chartDownloadsPerMediaspot.MM =
			calculateAggregatedPerPeriod(aggregatedAnalytics.chartDownloadsPerMediaspot.hh, function(prevPeriodDate, currentPeriodDate){
				return prevPeriodDate == null || moment(prevPeriodDate).month() !== moment(currentPeriodDate).month();
			});

			//top files
			_.each(_topPerHours, function(hours){
				// aggregatedAnalytics['topFiles' + (hours || '')] = calculateTopFiles(goodMediaspots, hours);
				_.assign(aggregatedAnalytics, calculateTopFiles(goodMediaspots, hours));
			});

			aggregatedAnalytics.chartDownloadsPerDevice = calculateDevicesAnalitycs(goodMediaspots);


			return aggregatedAnalytics;
		}

		return {
			generateAnalytics: generateAnalytics
		}
	})();

});