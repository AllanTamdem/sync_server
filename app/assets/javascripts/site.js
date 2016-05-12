

$.ajaxSetup({
  cache: false
});


var SyncServer = {
	gOldOnError: window.onerror,
	unloadingState: false
};

SyncServer.log = function(action_type, content){
	// $.ajax({
	// 	global: false, //so it doesn't trigger ajaxError if it fails again
	//   type: "POST",
	//   url: "/logs/create",
	//   data: {
	// 		action_type: action_type,
	// 		url: document.URL,
	// 		content: content
	// 	}
	// });
};


SyncServer.logJsError = function(content){
		$.ajax({
			global: false, //so it doesn't trigger ajaxError if it fails again
		  type: "POST",
		  url: "/logs/create_rails_log",
		  data: {
				action_type: 'JAVASCRIPT_ERROR',
				url: document.URL,
				content: content
			}
		});
};


SyncServer.getBrowserInfo = function(){
    var ua= navigator.userAgent, tem, 
    M= ua.match(/(opera|chrome|safari|firefox|msie|trident(?=\/))\/?\s*(\d+)/i) || [];
    if(/trident/i.test(M[1])){
        tem=  /\brv[ :]+(\d+)/g.exec(ua) || [];
        return 'IE '+(tem[1] || '');
    }
    if(M[1]=== 'Chrome'){
        tem= ua.match(/\bOPR\/(\d+)/)
        if(tem!= null) return 'Opera '+tem[1];
    }
    M= M[2]? [M[1], M[2]]: [navigator.appName, navigator.appVersion, '-?'];
    if((tem= ua.match(/version\/(\d+)/i))!= null) M.splice(1, 1, tem[1]);
    return M.join(' ');
}

toastr.options.timeOut = 6000;

$(document).ajaxError(function(event, jqxhr, settings, thrownError) {
	
	if(thrownError == 'Unauthorized'){
		toastr.error(thrownError);
	}
	else{

		if(SyncServer.unloadingState == true){
			return;
		}

		toastr.error("Internal server error.");

		var browser = null;
		try{
			browser = SyncServer.getBrowserInfo();
		}
		catch(e){}

		$.ajax({
			global: false, //so it doesn't trigger ajaxError if it fails again
		  type: "POST",
		  url: "/logs/create_rails_log",
		  data: {
				action_type: 'AJAX_ERROR',
				url: document.URL,
				content: {
					browser: browser,
					unloadingState: SyncServer.unloadingState,
					ajax_type: settings.type,
					ajax_url: settings.url,
					ajax_data: settings.data,
					responseText: jqxhr.responseText
				}
			}
		});

	}
});

// Override previous handler.
window.onerror = function myErrorHandler(errorMsg, url, lineNumber, columnNumber, errorObj) {

	var browser = null;
	try{
		browser = SyncServer.getBrowserInfo();
	}
	catch(e){}

	var content = {
		errorMsg: errorMsg,
		url: url,
		lineNumber: lineNumber,
		columnNumber: columnNumber,
		browser: browser,
		errorStack : (errorObj || {}).stack
	};

	SyncServer.logJsError(content);

  if (SyncServer.gOldOnError)
    // Call previous handler.
    return SyncServer.gOldOnError(errorMsg, url, lineNumber, columnNumber, errorObj);
  

  // Just let default handler run.
  return false;
}

// when the page is closing
$(window).bind("beforeunload", function () {
    SyncServer.unloadingState = true;
});


SyncServer._constChartColors = ["#67b7dc", "#fdd400", "#84b761", "#cc4748", "#cd82ad", "#2f4074", "#448e4d", "#b7b83f", "#b9783f", "#b93e3d", "#913167"];
SyncServer._chartColorsHash = {};

SyncServer.getChartColorByKey = function(family, key){

	if(SyncServer._chartColorsHash[family] == undefined){
		SyncServer._chartColorsHash[family] = {
			colors: _.clone(SyncServer._constChartColors),
			hash:{}
		}
	}

	if(SyncServer._chartColorsHash[family].hash[key] == undefined){
		SyncServer._chartColorsHash[family].hash[key] = SyncServer._chartColorsHash[family].colors.shift();

		if(SyncServer._chartColorsHash[family].colors.length == 0)
			SyncServer._chartColorsHash[family].colors = _.clone(SyncServer._constChartColors);
	}

	return SyncServer._chartColorsHash[family].hash[key];
}

$(function(){	
	var storage = $.localStorage;

	$('.localstorage-hide').each(function(){
		var target = $(this).data('target');

		var key = 'localstorage-hide-' + target;

		if(storage.isSet(key) && storage.get(key) == true){
			$(target).hide();
		}
		else{
			$(target).show();
		}

	});


	$(document).on("click", ".localstorage-hide", function() {
		var target = $(this).data('target');		
    storage.set('localstorage-hide-' + target, true);
		$(target).hide();
		return false;
	});

});

function log(){
	if(console){
		console.log.apply(console, arguments);
	}
}

/**
 * $.parseParams - parse query string paramaters into an object.
 */
(function($) {
var re = /([^&=]+)=?([^&]*)/g;
var decodeRE = /\+/g;  // Regex for replacing addition symbol with a space
var decode = function (str) {return decodeURIComponent( str.replace(decodeRE, " ") );};
$.parseParams = function(query) {
    var params = {}, e;
    while ( e = re.exec(query) ) { 
        var k = decode( e[1] ), v = decode( e[2] );
        if (k.substring(k.length - 2) === '[]') {
            k = k.substring(0, k.length - 2);
            (params[k] || (params[k] = [])).push(v);
        }
        else params[k] = v;
    }
    return params;
};
})(jQuery);


(function($) {
$.parseHashParams = function() {
	var hashParams = {};
  var e,
      a = /\+/g,  // Regex for replacing addition symbol with a space
      r = /([^&;=]+)=?([^&;]*)/g,
      d = function (s) { return decodeURIComponent(s.replace(a, " ")); },
      q = window.location.hash.substring(1);

  while (e = r.exec(q))
     hashParams[d(e[1])] = d(e[2]);

  return hashParams;
};
})(jQuery);