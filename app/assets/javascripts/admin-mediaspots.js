"use strict";

var Page = {};

$(document).ready(function() {

    var selectedDevice = null;

    //expand level for the json view of the mediaspot details
    var expandLevel = 0;

    var tableClients = null;

    var LogMaxDisplay = 100;

    var table = $('#table-mediaspots').dataTable({
    	ajax: '/admin_mediaspots/get_mediaspots',
    	dom: '<"table-toolbar">frtip',
    	columns: [
            {
                data: "details.mediaspotName",
                title: 'Name',
                render:function(data, type, row){

                    var mediacenter = '';

                    if(row.details['summary.productClass'] == 'Mediacenter'){
                        var ipAdress = '';
                        try{
                            ipAdress = ' ' + row.details.InternetGatewayDevice.LANDevice[1].Hosts.Host[1].IPAddress._value;
                        }
                        catch(e){ console.log("can't access " + data + " mediacenter ip address at row.details.InternetGatewayDevice.LANDevice[1].Hosts.Host[1].IPAddress._value");}

                        mediacenter = ' <span class="label label-sm label-primary arrowed arrowed-right">MC'+ipAdress+'</span>';
                    }

                    return '<span class="name">' + data + '</span>' + mediacenter;
                }
            },
            { data: "details._id", title: 'ID' },
            { data: "listClientsNames", title: 'Content Providers' },
            {
                data: "details", title: 'Last contact received', 
                render: function(data, type, row){
                    var text = '<span style="display:none;">' + data.date_last_inform + '</span>'; //for sorting

                    if(row.details['connected'] == true){
                        text += '<i class="fa fa-circle" style="color:#0C0" title="online"></i> ';
                    } else{
                        text += '<i class="fa fa-circle" style="color:red" title="offline"></i> ';
                    }

                    text += data.date_last_inform_ago + ' <small>(' + data.date_last_inform + ')</small>';

                    return text;
                }
            },
            {
                data: "details", title: 'Information last updated', 
                render: function(data, type, row){
                    if(data.date_updated){
                        return '<span style="display:none;">' + data.date_updated + '</span>' //for sorting
                        + data.date_updated_ago + ' <small>(' + data.date_updated + ')</small>';
                    }
                    return '';
                }
            }
        ],
        language: {
          emptyTable: ' '
        },
        info: false,
        fnInitComplete: function() {
            setTimeout(function(){
                setTablePreviousState();
            },0);
        }
    });
    
    table.on('page.dt', function () {
        setTimeout(function(){
            var hashParams = $.parseHashParams();
            hashParams.page = $('.paginate_button.active').text();    
            window.location.hash = $.param(hashParams);
        },0);
    });
    table.on('order.dt', function (event, table, orders) {
        var hashParams = $.parseHashParams();

        if(hashParams.order_col !== orders[0].col + '' || hashParams.order_dir != orders[0].dir){
            hashParams.order_col = orders[0].col;
            hashParams.order_dir = orders[0].dir;
            hashParams.page = 1; //changing order always put the table back to the first page  
            window.location.hash = $.param(hashParams);
        }
    });
    table.on( 'search.dt', function () {
        setTimeout(function(){
            var hashParams = $.parseHashParams();
            if($('.dataTables_filter input[type=search]').val() != hashParams.search){
                hashParams.search = $('.dataTables_filter input[type=search]').val();    
                hashParams.page = 1; //a search always put the table back to the first page   
                window.location.hash = $.param(hashParams);
            }
        },0);
    } );

    Page.table = table;


    //refresh button
    $("#table-mediaspots_filter").prepend('<div style="float:left;"><button id="btn-refresh" data-loading-text="Loading..." class="btn btn-default btn-sm" autocomplete="off"><i class="fa fa-refresh"></i> Refresh</button></div>');


    // var selectedDeviceId;

    //refresh the table pf mediaspots
    //keep the medispot selected
    function refreshMediaspots(){
        
        // selectedDeviceId = null;

        // if(selectedDevice != null){
        //     selectedDeviceId = selectedDevice.details['_id'];
        // }

        //$('#details').hide();
        $("#btn-refresh").button('loading');
        //table.fnClearTable();
        table.api().ajax.reload(function(){

            $("#btn-refresh").button('reset');

            setTimeout(function(){
                setTablePreviousState();
            },0);

            // if(selectedDeviceId){

            //     var $row = $('#row_' + selectedDeviceId);
            //     if($row.length == 0){
            //         $('#details').hide();
            //         selectedDevice = null;
            //     }
            //     else{
            //         $row.trigger('click');
            //     }
            // }

        });
    }

    function setTablePreviousState(){        

        var hashParams = $.parseHashParams();

        if(hashParams.search){
            table.fnFilter(hashParams.search);
        }
        if(hashParams.order_col && hashParams.order_dir){
            table.fnSort([ [parseInt(hashParams.order_col, 10), hashParams.order_dir] ]);
        }
        if(hashParams.page){
            table.fnPageChange(parseInt(hashParams.page, 10) - 1);
        }

        if(hashParams.mediaspot){
           $('#table-mediaspots tbody tr').each(function(){
                if($(this).find('td:eq(0) .name').text() == hashParams.mediaspot){
                    $(this).click();
                }
            });
        }
    }

    //refresh table of mediaspots
    $(document).on("click", "#btn-refresh, .link-refresh", function() {
        refreshMediaspots();
        return false;
    });

    //rtoggle the wifi scan info
    $(document).on("click", "#wifi-scan-collapse-link", function() {
        $('#wifi-scan-collapse').slideToggle();
        return false;
    });


    function displayMediaSpot(data){

        // (function(){
        //     console.log('____')
        //     for(var client in data.details.InternetGatewayDevice.X_orange_tapngo.Clients){
        //         if(client != '_object' &&
        //         client != '_writable' &&
        //         client != '_timestamp'){
        //             var c = data.details.InternetGatewayDevice.X_orange_tapngo.Clients[client];

        //             console.log('-------')
        //             if(c.IsSyncing){
        //                 console.log(client + ' ' + c.ClientName._value + ' ' +
        //                     'IsSyncing = ' + c.IsSyncing._value);
        //             }

        //             var log = c.RepoSyncLog._value.split('\n');

        //             if(log.length-3 >= 0){
        //                 console.log('| ' + log[log.length-3])
        //             }
        //             if(log.length-2 >= 0){
        //                 console.log('| ' + log[log.length-2])
        //             }
        //             if(log.length-1 >= 0){
        //                 console.log('| ' + log[log.length-1])
        //             }
                    
        //         }

        //     }
        // })();

        $('#updating-loader').hide();

        selectedDevice = data;

        updateTasksPopover();

        //showing the json details
        $("#details-json-view").JSONView(data.details, {collapsed: true, nl2br: true});

        expandLevel = 1;
        $('#details-json-view').JSONView('toggle', expandLevel++);

        //write the name of the mediaspot

        var title = data.details['mediaspotName']? data.details['mediaspotName']: data.details['_id'];

        var version = data.details['InternetGatewayDevice']['DeviceInfo']['SoftwareVersion']['_value'];

        var hashParams = $.parseHashParams();
        hashParams.mediaspot = title;
        window.location.hash = $.param(hashParams);

        if(data.details['summary.productClass'] == 'Mediacenter'){

            var ipAdress = '';
            try{
                ipAdress = ' ('+data.details.InternetGatewayDevice.LANDevice[1].Hosts.Host[1].IPAddress._value+') ';
            }
            catch(e){ console.log("can't access " + data + " mediacenter ip address at row.details.InternetGatewayDevice.LANDevice[1].Hosts.Host[1].IPAddress._value");}

            $('#details-title').html('Mediacenter: ' + title + ipAdress + ' (version ' + version + ')');
        }
        else{
            $('#details-title').html('Mediaspot: ' + title + ' (version ' + version + ')');
        }
        
        //write when the mediaspot information was last updated
        // $('#details-date-updated').html(data.details['date_updated_ago']);        

        $('#details-date-updated').html(moment(new Date(data.details.date_updated)).format('ddd, MMM D [at] HH:mm [<small>]([GMT]ZZ)[</small>]'));

        $("#input-mediaspot-name").val(data.details['mediaspotName']);

        if(data.details['InternetGatewayDevice'] &&
            data.details['InternetGatewayDevice']['X_orange_tapngo'] &&            
            data.details['InternetGatewayDevice']['X_orange_tapngo']['MediacenterHost'] &&
            data.details['InternetGatewayDevice']['X_orange_tapngo']['MediacenterHost']['_value']){

            $("#input-mediaspot-mediacenter-host").val(data.details['InternetGatewayDevice']['X_orange_tapngo']['MediacenterHost']['_value']);
        }
        else {
            $("#input-mediaspot-mediacenter-host").val('');
        }



        if(data.details['InternetGatewayDevice'] &&
            data.details['InternetGatewayDevice']['X_orange_tapngo'] &&            
            data.details['InternetGatewayDevice']['X_orange_tapngo']['Tr069Host'] &&
            data.details['InternetGatewayDevice']['X_orange_tapngo']['Tr069Host']['_value']){

            $("#input-mediaspot-tr069-host").val(data.details['InternetGatewayDevice']['X_orange_tapngo']['Tr069Host']['_value']);
        }
        else {
            $("#input-mediaspot-tr069-host").val('');
        }



        if(data.details['InternetGatewayDevice'] &&
            data.details['InternetGatewayDevice']['X_orange_tapngo'] &&            
            data.details['InternetGatewayDevice']['X_orange_tapngo']['WebsocketHost'] &&
            data.details['InternetGatewayDevice']['X_orange_tapngo']['WebsocketHost']['_value']){

            $("#input-mediaspot-websocket-host").val(data.details['InternetGatewayDevice']['X_orange_tapngo']['WebsocketHost']['_value']);
        }
        else {
            $("#input-mediaspot-websocket-host").val('');
        }



        //the Logs tab
        $('#logs').html(data['Log']);

        //the SystemMonitor tab
        $('#system-monitor').html(data['SystemMonitor']);
        $('#system-info').html('');
        if(data.SystemInfo.memory_used_percent != null && data.SystemInfo.swap_used_percent != null ){
            $('#system-info').html('Mem used: ' + data.SystemInfo.memory_used_percent + '%\nSwap used: ' + data.SystemInfo.swap_used_percent + '%');
        }

        // internet white list
        $('#txt-internet-white-list').hide();
        $('#btn-save-internet-white-list').hide();
        $('#btn-cancel-internet-white-list').hide();
        $('#btn-edit-internet-white-list').show();
        $('#pre-internet-white-list').show();

        if(data['InternetWhitelist']){

            $('#pre-internet-white-list').html(data['InternetWhitelist']);
            $('#div-internet-white-list').show();
        }
        else{
            $('#div-internet-white-list').hide();
        }

        //internet blocking        
        if(data['InternetBlockingEnabled'] == 'true' || data['InternetBlockingEnabled'] == 'false'){
            $('#div-internet-blocking :checkbox').prop('checked', data['InternetBlockingEnabled'] == 'true')
            $('#div-internet-blocking').show();
        }
        else{
            $('#div-internet-blocking').hide();
        }


        // CustomInfo
        $('#txt-custom-info').hide();
        $('#btn-save-custom-info').hide();
        $('#btn-cancel-custom-info').hide();
        $('#btn-edit-custom-info').show();
        $('#pre-custom-info').show();

        if(data['MediaspotCustomInfo']){

            try{
                data['MediaspotCustomInfo'] = JSON.stringify(JSON.parse(data['MediaspotCustomInfo']), null, 2);
            }
            catch(e){}

            $('#pre-custom-info').html(data['MediaspotCustomInfo']);
            $('#div-custom-info').show();
        }
        else{
            $('#div-custom-info').hide();
        }

        wifiTab.init(data.details.InternetGatewayDevice.X_orange_tapngo.Wifis || {});

        if(data.WifiSurvey){
            var wifiSurveyHtml = '<hr><button id="wifi-scan-collapse-link" class="btn-view-index-json btn btn-info btn-sm"><i class="fa fa-info-circle"></i> View Wi-Fi scan information</button>';
            wifiSurveyHtml += '<div id="wifi-scan-collapse" style="display:none;" ><pre>' + data.WifiSurvey + '</pre></div>'
            $('#wifi-survey').html(wifiSurveyHtml);
        }
        else{
            $('#wifi-survey').html('');
        }


        //wifi wan settings
        if(data.details.InternetGatewayDevice.X_orange_tapngo.WanwifiPsk &&
            data.details.InternetGatewayDevice.X_orange_tapngo.WanwifiSsid){

            $('#input-wan-wifi-ssid').val(data.details.InternetGatewayDevice.X_orange_tapngo.WanwifiSsid._value);
            $('#input-wan-wifi-psk').val(data.details.InternetGatewayDevice.X_orange_tapngo.WanwifiPsk._value);
            $('#wifi-wan-settings').show();

        }
        else{
            $('#wifi-wan-settings').hide();
        }


        if(data.details.InternetGatewayDevice.X_orange_tapngo.WelcomepageTree &&
            data.details.InternetGatewayDevice.X_orange_tapngo.WelcomepageZipUrl){

            $('#welcome-page-settings').show();
            $('#welcome-page-tree').html(data.details.InternetGatewayDevice.X_orange_tapngo.WelcomepageTree._value || '');
        }
        else{
            $('#welcome-page-settings').hide();
        }


        //empty the task queue
        $('#div-task-queue').html('');


        // var clients = $.param({clients:['awww','beeee']})
        var clientNames = _.map(data.clients, function(c){
            return c.ClientName._value
        });

        fetchLatestFileDate(clientNames, function(repoDates){

            _.each(data.clients, function(client){

                var repoDate = repoDates[client.ClientName._value];

                var isSynced = null;

                if(repoDate == null){
                    isSynced = true;
                }
                else if(client.synced_date == null){
                    isSynced = false;
                }
                else{
                    var moment_synced_date = moment(client.synced_date, "YYYY-MM-DD HH:mm:ss.SSSSSSSSS ZZ");

                    if(moment_synced_date.isValid() && repoDate.isValid()){
                        isSynced = repoDate <= moment_synced_date;
                    }
                }

                var tag = '<span class="red">Error while reading the sync status</span>';

                if(isSynced === true){
                    tag = '<i class="fa fa-check-circle" style="color:blue"></i> synced';
                }
                else if(isSynced === false){
                    tag = '<i class="fa fa-times-circle" style="color:orange"></i> out of sync';
                }

                $('.sync-status[data-client=' + client.ClientName._value + ']').html(tag);

            });
        });


        //destroying the clients table to rebuild a new one
        if(tableClients){
            //tableClients.api().destroy();
            tableClients.fnClearTable();
            if(data.clients.length > 0){
                tableClients.fnAddData(data.clients);
            }
        }
        else{
            tableClients = $('#table-clients').dataTable({
                data: data.clients,
                columns: [{
                    orderable: false,
                    data: null,
                    defaultContent: '<button class="btn-remove-client btn btn-danger btn-sm" data-toggle="tooltip" title="Click to remove this content provider from the mediaspot"><i class="fa fa-times"></i></button>'
                }, {
                    data: 'name',
                    title: 'Content provider',
                    render: function(data, type, row){
                        var content = data;

                        if(row.RepoCredentials){
                            var json_repo_credentials = null;
                            try{
                                json_repo_credentials = JSON.parse(row.RepoCredentials._value);
                            }
                            catch(e){}

                            if(json_repo_credentials &&
                                json_repo_credentials.bucketname &&
                                json_repo_credentials.bucketname != SyncServer.default_bucket){

                                content += '<br><small class="text-info" ><i class="fa fa-info-circle" data-toggle="tooltip" title="This content provider is using a different S3 bucket than the default sync-server\'s bucket"></i> ' + 
                                'Non-default S3 bucket:<br><b>' + json_repo_credentials.bucketname + '</b></small>';
                            }
                        }
                        
                        return content;
                    }
                }, {
                    data: 'DownloadEnabled._value',
                    title: 'Download enabled',
                    render: function(data){

                        var checked = data == true? 'checked="checked"' : '';

                        var sorting = '<span style="display:none;">' + data + '</span>';

                        var checkbox = '<div style="float:left;">'
                            + '<label><input name="switch-field-1" class="chk-dl-enabled ace ace-switch ace-switch-4 btn-flat" type="checkbox" ' + checked + ' >'
                            + '<span class="lbl"></span></label>'
                        + '</div>';

                        var accessLogBtn = '<div style="margin-left:64px;">'
                        + '<button class="btn-view-access-logs btn btn-info btn-minier"><i class="fa fa-info-circle"></i> Access logs</button>'
                        + '</div>';

                        return sorting + checkbox + accessLogBtn;
                    }
                }, {
                    title: 'Repository synchronization',
                    orderable: false,
                    render:function(data, type, row){

                        var textBtnSync = ' <button class="btn-sync-now btn btn-primary btn-minier">'
                            +'<i class="fa fa-cloud-download ace-icon"></i> Synchronize now'
                        + '</button> ';

                        var textBtnLog = ' <button class="btn-view-sync-logs btn btn-info btn-minier"><i class="fa fa-info-circle"></i> Sync logs</button> ';

                        var lastSynced = '';
                        if(row.synced_ago) lastSynced = ' <b>Last update ' + row.synced_ago + '</b> ';

                        var syncing = '';
                        if(row.syncing) syncing = '<br><b class="green">Syncing...</b>';

                        var error = '';
                        if(row.sync_error) error = '<br><b class="red"><i class="fa fa-exclamation-triangle"></i> ERROR (see logs).</b>';

                        var stuck = '';
                        if(row.IsSyncing && row.IsSyncing._value == 'stuck')
                            stuck = '<br><b class="red2"><i class="fa fa-exclamation-triangle"></i> The synchronization seems to be stuck.</b>';

                        var syncStatus = '<br><span class="sync-status" data-client="' + row.ClientName._value + '">Loading...</span>'

                        if(row.syncing || row.sync_error)
                            syncStatus = '';

                        return textBtnSync + textBtnLog + syncStatus + error + syncing + stuck;
                    }
                }, {
                    title: 'Token-based authentication secret',
                    orderable: false,
                    render:function(data, type, row){
                        var token = '';
                        if('DownloadAuthTokenSecret' in row && '_value' in row.DownloadAuthTokenSecret){
                            token = row.DownloadAuthTokenSecret._value;
                        }
                        var textBtn = '<button class="btn-change-token btn btn-primary btn-sm"><i class="fa fa-pencil-square-o"></i></button>';
                        return '<div style="min-width:200px;"><input type="text" class="col-xs-12 col-sm-8" value="' + token + '" disabled="disabled">' + textBtn + '</div>';
                    }
                }, {
                    title: 'Files',
                    orderable: false,
                    render:function(data, type, row){
                        var btnIndexJson = '';
                        var btnContentsTree = '';

                        if(row.IndexJson) {
                            btnIndexJson = '<button class="btn-view-index-json btn btn-info btn-minier"><i class="fa fa-info-circle"></i> Index JSON</button>';
                        }
                        
                        if(row.ContentsTree) {
                            btnContentsTree = '<button class="btn-view-contents-tree btn btn-info btn-minier"><i class="fa fa-info-circle"></i> Contents tree</button>';
                        }

                        return btnIndexJson + ' ' + btnContentsTree;
                    }
                }, {
                    title: 'Analytics',
                    orderable: false,
                    render: function(data, type, row){
                        if(row.MakeAnalyticsNow){
                            return '<button class="btn-make-analytics-now btn btn-primary btn-minier">'
                                +'<i class="fa fa-bar-chart ace-icon"></i> Generate analytics now'
                            + '</button>';
                        }

                        return '';
                    }
                }],
                lengthChange: false,
                paging: false,
                searching: false,
                info: false,
                order: [[2, 'asc']],
                language: {
                  emptyTable: "No clients on this mediaspot"
                }
            });
        }

        $('[data-toggle="tooltip"]').tooltip();


        $('#details').show();
    }


    var wifiTab = (function () {

        var _fields = [
            { name: 'Interface', display_name: 'Interface'},
            { name: 'Band', display_name: 'Band'},
            { name: 'RadioEnabled', display_name: 'Radio Enabled', type: 'boolean'},
            { name: 'Ssid', display_name: 'SSID'},
            { name: 'Channel', display_name: 'Channel', options: function(interfac){
                    if(interfac.Band && interfac.Band._value == '2.4 GHz'){
                        return _.range(1, 14);
                    }
                    if(interfac.Band && interfac.Band._value == '60 GHz'){
                        return ['1/2160', '2/2160', '3/2160', '4/2160'];
                    }
                    return ['36/80', '40/80', '44/80', '48/80', '52/80', '56/80', '60/80', '64/80', '100/80', '104/80', '108/80', '112/80', '116/80', '120/80', '124/80', '128/80', '132/80', '136/80', '140/80'];
                }
            },
            { name: 'TxPower', display_name: 'Transmit Power (%)', type: 'percent'},
            { name: 'WpaPassword', display_name: 'WPA Password'},
            { name: 'BssUtilization', display_name: 'This BSS Channel Utilization (%)'},
            { name: 'ObssUtilization', display_name: 'OBSS Channel Utilization (%)'},
            { name: 'Idle', display_name: 'Idle Channel (%)'}
        ]


        // var _knownedFields = [
        //     {name:'RadioEnabled', type: 'boolean'}
        // ];

        function isInt(value){
            return (parseInt(value, 10)+'') == value + '';
        }

        function isPercent(value){
            if(!isInt(value))
                return false;

            var i = parseInt(value, 10);

            return (i >= 0 && i <= 100);
        }

        $(document).on('keyup change', '#wifi-settings input, #wifi-settings select', function() {
            var $this = $(this);
            var value = this.type == 'checkbox'? $this.is(':checked') + '' : $this.val();
            value = (value + '').trim();
            var oldValue = $this.data('old-value') + '';

            if($(this).data('type') == 'boolean'){
                var url = '/admin_mediaspots/set_mediaspot_wifi_setting?'
                + 'device-id=' + selectedDevice.details['_id']
                + '&interfac=' + $this.data('interface')
                + '&key=' + $this.data('key')
                + '&value=' + value;

                submitTask(url);                
            }
            else{
                if($this.data('type') == 'percent' && !isPercent(value.trim())){
                    $this.toggleClass('changed', false);
                    $this.toggleClass('error', true);
                }
                else{
                    $this.toggleClass('error', false);
                    $this.toggleClass('changed', value !== oldValue);
                }
            }

            if($('#wifi-settings .changed, #wifi-settings .error').length > 0){
                $('#save-wifi-settings').removeAttr('disabled');
            }
            else{
                $('#save-wifi-settings').attr('disabled', 'disabled');
            }
        });


        $(document).on('click', '#save-wifi-settings', function() {

            var tasks = [];
            var errors = [];

            $('#wifi-settings .changed, #wifi-settings .error').each(function(){
                var $this = $(this);
                var value = this.type == 'checkbox'? $this.is(':checked') + '' : $this.val();
                value = value.trim();
                var interfac = $this.data('interface');
                var key = $this.data('key');
                var type = $this.data('type');

                if(type == 'int' && !isInt(value)){
                    errors.push('The field "' + key + '" must be an integer');
                }
                else if(type == 'percent' && !isPercent(value)){
                    errors.push('The field "' + key + '" must be an integer between 1 and 100');
                }
                else {
                    tasks.push({
                        interfac:interfac,
                        key:key,
                        value:value
                    });
                }
            });

            if(errors.length > 0){
                toastr.error(errors.join('<br>'));
            }
            else if(tasks.length == 0){
                toastr.warning('No changes to save');
            }
            else{
                _.each(tasks, function(task){
                    
                    var url = '/admin_mediaspots/set_mediaspot_wifi_setting?'
                    + 'device-id=' + selectedDevice.details['_id']
                    + '&interfac=' + task.interfac
                    + '&key=' + task.key
                    + '&value=' + task.value;

                    submitTask(url);
                });
            }
            return false;
        });
 
        function init(interfaces){

            var rows = _.filter(_.keys(interfaces), isInt);

            if(rows.length == 0){
                $('#wifi-settings').html('');
            }
            else{
                var table = '<table class="table table-hover table-condensed table-hover table-bordered table-striped"><thead><tr><th>';

                table += _.pluck(_fields, 'display_name').join('</th><th>');

                table += '</th></tr></thead><tbody>';

                _.each(rows, function(row){
                    table += '<tr>';

                    _.each(_fields, function(_field){
                        var field = interfaces[row][_field.name];

                        if(field){
                            if(field._writable){
                                if(_field.type == 'boolean'){
                                    var checked = '';
                                    var value = (field._value + '').toLowerCase();
                                    if(value === 'true'){
                                        checked = 'checked="checked"';
                                    }
                                    table += '<td><label><input data-interface="' + row + '" data-key="' + _field.name + '" data-type="' + _field.type + '" ';
                                    table += checked + ' data-old-value="' + value + '"';
                                    table += 'class="ace ace-switch ace-switch-4 btn-flat" type="checkbox">';
                                    table += '<span class="lbl"></span></label></td>';
                                }
                                else if(_field.options){

                                    var options = _field.options(interfaces[row]);

                                    var select = '<select class="form-control" data-interface="' + row + '" data-key="' + _field.name + '" ';
                                    select += ' data-old-value="' + field._value + '" data-type="options" >';
                                    select += '<option></option>';

                                    _.each(options, function(o){
                                        var selected = '';

                                        if(o == field._value){
                                            selected = 'selected="selected"';
                                        }

                                        select += '<option ' + selected + ' >' + o + '</option>';
                                    })
                                    select += '</select>';

                                    table += '<td>' + select + '</td>';
                                }
                                else{
                                    table += '<td><input data-interface="' + row + '" ';
                                    table += ' data-key="' + _field.name + '" data-type="' + (_field.type || 'string') + '" ';
                                    table += ' data-old-value="' + field._value + '"';
                                    table += 'class="form-control" type="text" value="' + field._value + '"></td>';
                                }
                            }
                            else{
                                table += '<td>' +  field._value + '</td>';
                            }
                        }
                        else{
                            table += '<td></td>';
                        }

                    });

                    table += '</tr>';
                })

                table += '</tbody></table>';

                var btn = '<button id="save-wifi-settings" class="btn btn-sm btn-primary" disabled="disabled">Save changes</button>';

                $('#wifi-settings').html(table + btn);
            }

        }
     
      return {
        init: init
      };
     
    })();

    //click on mediaspot row
    $('#table-mediaspots tbody').on('click', 'tr', function () {
        
        var data = table.api().row(this).data();

        if(data){
            $('#table-mediaspots tbody tr').removeClass('warning');
            $(this).addClass('warning');
            displayMediaSpot(data);
        }
    });

    //json details collapse/expand
    $('#btn-collapse').on('click', function() {
        --expandLevel;
        if(expandLevel == 0) expandLevel = 1;

        $('#details-json-view').JSONView('collapse', expandLevel);
    });
    $('#btn-expand').on('click', function() {
        $('#details-json-view').JSONView('expand', expandLevel++);
    });


    //click on the add client button
    $('#modal-change-token').on('shown.bs.modal', function () {
        $('#client-token').focus();
    })

    //add client show modal
    $('#btn-add-client').on('click', function() { 
        $('#content_provider_technical_name').val('');

        $('#content_provider_technical_name option').show();

        $('#content_provider_technical_name').find('option').each(function(i, option){

            //if this content provider is already in the mediaspot
            if(_.some(selectedDevice.clients, function(c){
                return option.value == c.ClientName._value;
            })){
                //we hide it
                $(option).hide();
            }
        });


        $('#modal-add-client').modal('show');

        return false;
    });

    // submit add client

    function addClient(){
        if($('#content_provider_technical_name').val() == '')
            return;

        var url = '/admin_mediaspots/add_client?device-id=' + selectedDevice.details['_id'] + '&client-name=' + $('#content_provider_technical_name').val();

        $('#modal-add-client').modal('hide');

        submitTask(url);
    }
    $('#modal-add-client form').on('submit', function() {
        addClient();
        return false;
    });
    $('#btn-add-client-submit').on('click', function() {
        addClient();
        return false;
    });

    // remove client
    $(document).on("click", '#table-clients tbody .btn-remove-client', function() {

        var $btn = $(this);
        var data = tableClients.api().row($btn.closest('tr')[0]).data();


        if(confirm('Are you sure you want to remove the client "' +
            data.ClientName._value +
            '" from ' + selectedDevice.details['mediaspotName'])){        

            var url = '/admin_mediaspots/remove_client?device-id=' + selectedDevice.details['_id'] + '&client-name=' + data.ClientName._value;
            submitTask(url);
        }

        return false;
    });


    //changing "Download enabled"
    $(document).on("change", '.chk-dl-enabled', function(e) {

        var data = tableClients.api().row($(this).closest('tr')[0]).data();

        var url = '/admin_mediaspots/set_client_parameter?'
        + 'device-id=' + selectedDevice.details['_id']
        + '&client-number=' + data.number
        + '&parameter-name=' + 'DownloadEnabled'
        + '&parameter-value=' + this.checked;

        
        submitTask(url);

        //this.checked = !this.checked;
        //return false;
    });


    // Make Analytics now
    $(document).on("click", '#table-clients tbody .btn-make-analytics-now', function() {

        var $btn = $(this);
        var data = tableClients.api().row($btn.closest('tr')[0]).data();
        

        var url = '/admin_mediaspots/set_client_parameter?'
        + 'device-id=' + selectedDevice.details['_id']
        + '&client-number=' + data.number
        + '&parameter-name=' + 'MakeAnalyticsNow'
        + '&parameter-value=' + 'true';

        submitTask(url);

        return false;
    });


    // Sync now
    $(document).on("click", '#table-clients tbody .btn-sync-now', function() {

        var $btn = $(this);
        var data = tableClients.api().row($btn.closest('tr')[0]).data();
        

        var url = '/admin_mediaspots/set_client_parameter?'
        + 'device-id=' + selectedDevice.details['_id']
        + '&client-number=' + data.number
        + '&parameter-name=' + 'SyncNow'
        + '&parameter-value=' + 'true';

        submitTask(url);

        return false;
    });

    function refreshDevice(deviceId){
        var url = '/admin_mediaspots/refresh_all?'
        + 'device-id=' + deviceId

        submitTask(url);
    }


    // refresh all parameters
    $(document).on("click", '#btn-refresh-all', function() {

        refreshDevice(selectedDevice.details['_id']);

        return false;
    });

    // change mediaspot name
    $(document).on("submit", '#form-mediaspot-name', function() {

        setMediaspotParameter({
            mediaspot_id: selectedDevice.details['_id'],
            key: 'MediaspotName',
            value: $('#input-mediaspot-name').val()
        })

        return false;
    });  

    // change wan wifi ssid
    $(document).on("submit", '#form-wan-wifi-ssid', function() { 

        setMediaspotParameter({
            mediaspot_id: selectedDevice.details['_id'],
            key: 'WanwifiSsid',
            value: $('#input-wan-wifi-ssid').val()
        })

        return false;
    }); 

    // change wan wifi psk (password)
    $(document).on("submit", '#form-wan-wifi-psk', function() { 

        setMediaspotParameter({
            mediaspot_id: selectedDevice.details['_id'],
            key: 'WanwifiPsk',
            value: $('#input-wan-wifi-psk').val()
        })

        return false;
    }); 

    // change welcome page zip url
    $(document).on("submit", '#form-welcome-page-zip-url', function() { 

        setMediaspotParameter({
            mediaspot_id: selectedDevice.details['_id'],
            key: 'WelcomepageZipUrl',
            value: $('#input-welcome-page-zip-url').val()
        })

        return false;
    });  

    // change mediaspot mediacenter host
    $(document).on("submit", '#form-mediaspot-mediacenter-host', function() { 

        setMediaspotParameter({
            mediaspot_id: selectedDevice.details['_id'],
            key: 'MediacenterHost',
            value: $('#input-mediaspot-mediacenter-host').val()
        })

        return false;
    }); 

    // change mediaspot TR069 host
    $(document).on("submit", '#form-mediaspot-tr069-host', function() {

        setMediaspotParameter({
            mediaspot_id: selectedDevice.details['_id'],
            key: 'Tr069Host',
            value: $('#input-mediaspot-tr069-host').val()
        })

        return false;
    });  

    // change mediaspot websocket host
    $(document).on("submit", '#form-mediaspot-websocket-host', function() { 

        setMediaspotParameter({
            mediaspot_id: selectedDevice.details['_id'],
            key: 'WebsocketHost',
            value: $('#input-mediaspot-websocket-host').val()
        })

        return false;
    });   



    // disable the buttons so the user can't start an action while an action is currently happening
    function disableButtons(){
        $('#details').find('.btn, [type=checkbox]').attr('disabled', 'disabled');
    }
    // re-enable the buttons
    function enableButtons(){
        $('#details').find('.btn, [type=checkbox]').removeAttr('disabled')
    }


    //submit a task to set a parameter on the mediaspot
    function setMediaspotParameter(options) {

        $.post('admin_mediaspots/set_mediaspot_parameter', {
            mediaspot_id: options.mediaspot_id,
            key: options.key,
            value: options.value
        })
        .done(function(){
            toastr.info('Task added to the queue.');
        })
    }

    //submit a task to the mediaspot
    function submitTask(url, callback) {

        //$('#progress-bar-client').show();
        //disableButtons();

        $.get(url, function(result){
            //$('#progress-bar-client').hide();
            //enableButtons();
            if(result.sync_already_running){
                toastr.warning('Task already processing');
            }
            else if(result.sync_already_in_queue){
                toastr.warning('Task already in the queue');
            }
            else{
                toastr.info('Task added to the queue.');
            }
        });
    }

    // view the access logs of one client
    $(document).on("click", '#table-clients tbody .btn-view-access-logs', function() {

        var $btn = $(this);
        var data = tableClients.api().row($btn.closest('tr')[0]).data();

        $('#modal-view-client-logs').modal('show')
        .find('.modal-body').html('<pre>' + data.DownloadAccessLog._value + '</pre>');

        $('#modal-view-client-logs').find('.modal-title').html('Access logs for ' + data.name + ' on <b>'
            + selectedDevice.details.mediaspotName + '</b> ');

        return false;
    });

    // view the sync logs of one client
    $(document).on("click", '#table-clients tbody .btn-view-sync-logs', function() {

        var $btn = $(this);
        var data = tableClients.api().row($btn.closest('tr')[0]).data();

        $('#modal-view-client-logs').modal('show')
        .find('.modal-body').html('<pre>' + data.RepoSyncLog._value + '</pre>');

        var title = 'Repository synchronization logs for ' + data.name + ' on <b>'
            + selectedDevice.details.mediaspotName + '</b>';
        // if(data.synced_ago){
        //     title += '<br>Last updated ' + data.synced_ago;
        // }
        if(data.synced_date){
            title += '<br>Last updated ' + moment(data.synced_date, "YYYY-MM-DD HH:mm:ss.SSSSSSSSS ZZ").format('ddd, MMM D [at] HH:mm [<small>]([GMT]ZZ)[</small>]');
        }

        $('#modal-view-client-logs').find('.modal-title').html(title);

        return false;
    });

    // view the index.json of one client
    $(document).on("click", '#table-clients tbody .btn-view-index-json', function() {

        var $btn = $(this);
        var data = tableClients.api().row($btn.closest('tr')[0]).data();
        // console.log(data.IndexJson._value);
        var niceJson = ''
        try{
            niceJson = JSON.stringify(JSON.parse(data.IndexJson._value), null, 2);
        }
        catch(e){}

        $('#modal-view-client-logs').modal('show')
        .find('.modal-body').html('<pre>' + niceJson + '</pre>');

        $('#modal-view-client-logs').find('.modal-title').html('Index.json of ' + data.name + ' on <b>'
            + selectedDevice.details.mediaspotName + '</b>');

        return false;
    });

    // view the contents tree of one client
    $(document).on("click", '#table-clients tbody .btn-view-contents-tree', function() {

        var $btn = $(this);
        var data = tableClients.api().row($btn.closest('tr')[0]).data();

        $('#modal-view-client-logs').modal('show')
        .find('.modal-body').html('<pre>' + data.ContentsTree._value + '</pre>');

        $('#modal-view-client-logs').find('.modal-title').html('Contents tree of ' + data.name + ' on <b>'
            + selectedDevice.details.mediaspotName + '</b>');

        return false;
    });



    // submit change the auth token Secret

    function changeToken(){

        var clientNumber = $('#client-number').val();
        var token = $('#client-token').val();

        var url = '/admin_mediaspots/set_client_parameter?'
        + 'device-id=' + selectedDevice.details['_id']
        + '&client-number=' + clientNumber
        + '&parameter-name=' + 'DownloadAuthTokenSecret'
        + '&parameter-value=' + token;

        submitTask(url);
    }

    $('#modal-change-token form').on('submit', function() {
        changeToken();
        $('#modal-change-token').modal('hide');
        return false;
    });
    $('#btn-change-token-submit').on('click', function() {
        changeToken();
        $('#modal-change-token').modal('hide');
        return false;
    });


    // Change the auth token Secret
    $(document).on("click", '#table-clients tbody .btn-change-token', function() {

        var $btn = $(this);
        var data = tableClients.api().row($btn.closest('tr')[0]).data();

        $('#client-token').val(data.DownloadAuthTokenSecret._value);
        $('#client-number').val(data.number);
        $('#modal-change-token').modal('show');

        $('#modal-change-token').find('.modal-title').html(data.name + ' on <b>'
            + selectedDevice.details.mediaspotName + '</b>');

        $('#client-token').focus();

        return false;
    });


    // delete mediaspot
    $(document).on("click", '.btn-delete-mediaspot', function() {
        
        $('#progress-bar-client').show();
        disableButtons();

        $.get('/admin_mediaspots/delete_mediaspot?device-id=' + selectedDevice.details._id, function(){
            toastr.info('The mediaspot ' + selectedDevice.details.mediaspotName + ' is being deleted.');         
            $('#progress-bar-client').hide();
            enableButtons();
            refreshMediaspots();

            $('#details').hide();
        });

        return false;
    });

    // reboot mediaspot
    $(document).on("click", '.btn-reboot-mediaspot', function() {
        
        $('#progress-bar-client').show();
        disableButtons();

        $.get('/admin_mediaspots/reboot_mediaspot?device-id=' + selectedDevice.details._id, function(){
            toastr.info('The mediaspot ' + selectedDevice.details.mediaspotName + ' is being rebooted.');         
            $('#progress-bar-client').hide();
            enableButtons();
            refreshMediaspots();

            $('#details').hide();
        });

        return false;
    });



    //changing "InternetBlockingEnabled"
    $(document).on("change", '#div-internet-blocking :checkbox', function(e) {

        var isChecked = $('#div-internet-blocking :checkbox').is(':checked');

        $.post('/admin_mediaspots/set_mediaspot_internet_blocking_enabled',{
            internet_blocking_enabled: isChecked,
            device_id: selectedDevice.details['_id']
        }, function(){
            toastr.info('Task added to the queue.');
        });

        return false;
    });


    // editing the field custom info
    $(document).on("click", '#btn-edit-custom-info', function() {

        $('#btn-edit-custom-info').hide();
        $('#pre-custom-info').hide();
        $('#txt-custom-info').val(selectedDevice.MediaspotCustomInfo||'')
        $('#txt-custom-info').show();
        $('#btn-save-custom-info').show();
        $('#btn-cancel-custom-info').show();
        return false;
    });

    // canceling the edition of the internet white list
    $(document).on("click", '#btn-cancel-custom-info', function() {

        $('#btn-edit-custom-info').show();
        $('#pre-custom-info').show();
        $('#pre-custom-info').html(selectedDevice.MediaspotCustomInfo || '')
        $('#txt-custom-info').hide();
        $('#btn-save-custom-info').hide();
        $('#btn-cancel-custom-info').hide();
        return false;
    });    

    // saving the new internet white list
    $(document).on("click", '#btn-save-custom-info', function() {

        var val = $('#txt-custom-info').val();

        try{
            JSON.parse(val)
        }
        catch(e){
            toastr.error('The JSON entered is invalid<br>' + e);
            return;
        }

        $.post('/admin_mediaspots/set_mediaspot_custom_info',{
            custom_info: val,
            device_id: selectedDevice.details['_id']
        }, function(response){
            if(response.error){
                toastr.error(response.error);
            }
            else{
                toastr.info('Task added to the queue.');
            }
        })

        $('#btn-edit-custom-info').show();
        $('#pre-custom-info').show();
        $('#pre-custom-info').html(val)
        $('#txt-custom-info').hide();
        $('#btn-save-custom-info').hide();
        $('#btn-cancel-custom-info').hide();
        return false;
    });




    // editing the internet white list
    $(document).on("click", '#btn-edit-internet-white-list', function() {

        $('#btn-edit-internet-white-list').hide();
        $('#pre-internet-white-list').hide();
        $('#txt-internet-white-list').val(selectedDevice.InternetWhitelist||'')
        $('#txt-internet-white-list').show();
        $('#btn-save-internet-white-list').show();
        $('#btn-cancel-internet-white-list').show();
        return false;
    });

    // canceling the edition of the internet white list
    $(document).on("click", '#btn-cancel-internet-white-list', function() {

        $('#btn-edit-internet-white-list').show();
        $('#pre-internet-white-list').show();
        $('#pre-internet-white-list').html(selectedDevice.InternetWhitelist||'')
        $('#txt-internet-white-list').hide();
        $('#btn-save-internet-white-list').hide();
        $('#btn-cancel-internet-white-list').hide();
        return false;
    });

    // saving the new internet white list
    $(document).on("click", '#btn-save-internet-white-list', function() {

        var val = $('#txt-internet-white-list').val();

        $.post('/admin_mediaspots/set_mediaspot_internet_white_list',{
            internet_white_list: val,
            device_id: selectedDevice.details['_id']
        }, function(){
            toastr.info('Task added to the queue.');
        });

        $('#btn-edit-internet-white-list').show();
        $('#pre-internet-white-list').show();
        $('#pre-internet-white-list').html(val)
        $('#txt-internet-white-list').hide();
        $('#btn-save-internet-white-list').hide();
        $('#btn-cancel-internet-white-list').hide();
        return false;
    });


    function fetchLatestFileDate(clients, cb){

        var clientsParam = $.param({clients:clients})

        var url = '/s3/get_files_with_last_modified_date?' + clientsParam;

        $.getJSON(url)
        .done(function(result){

            var dates = {};

            _.each(clients, function(client){

                var files = _.filter(result[client].data, function(f){
                    return _.contains(f.key, '.staging/') == false;
                });

                var latestDate = null;

                if(files.length > 0){

                    var lastestFile = _.max(files, function(f){
                        return moment(f.head.last_modified);
                    });
                    latestDate = moment(lastestFile.head.last_modified);
                }

                dates[client] = latestDate;
            })

            cb(dates);
        });
    }


    // delete all tasks of a mediaspot
    $(document).on("click", '#btn-delete-tasks', function() {

        var id = selectedDevice.details['_id'];

        $.get("/admin_mediaspots/delete_mediaspot_tasks?device-id=" + id)
        .done(function(result) {
            toastr.info('The tasks of ' + selectedDevice.details['mediaspotName'] + ' are being deleted.');
        });
        
        return false;
    });


    function updateTasksPopover(){

        var tasks = [];

        if(selectedDevice != null){
            tasks = _.filter(_tasks, function(t){return t.device == selectedDevice.details._id});
        }

        if(tasks.length == 0){
            $('#btn-running-tasks').html('');
            $('#btn-delete-tasks').hide();
            return;
        }

        var currentHtml = $('#btn-running-tasks').html();

        var popoverHtml = '<table class="table table-bordered">';

        _.each(tasks, function(task){

            var htmlTr = '<tr><td><b>' + task.name + '</b> ';
            if(task.parameterNames && task.parameterNames.length > 0){
                htmlTr += task.parameterNames.join(', ');
            }
            if(task.parameterValues && task.parameterValues.length > 0){
                htmlTr += task.parameterValues.join(', ');
            }
            if(task.objectName){
                htmlTr += task.objectName;
            }
            htmlTr += '</td></tr>';
            popoverHtml += htmlTr
        })
        popoverHtml += '</table>';

        if(currentHtml == ''){
            $('#btn-running-tasks').html('<span class="label">' + tasks.length + ' running tasks</span>');
            $('#btn-running-tasks .label').popover({
                container: '#btn-running-tasks',
                placement: 'bottom',
                title: 'Running tasks',
                // title: 'Running tasks &nbsp;<a class="btn-remove-tasks btn btn-minier btn-danger pull-right">remove all tasks</a>',
                html: true,
                trigger: 'hover',
                content: popoverHtml
            })
        }
        else{
            $('#btn-running-tasks .label').html(tasks.length + ' running tasks');


            var popover = $('#btn-running-tasks .label').data('bs.popover');
            popover.options.content = popoverHtml;
            $("#btn-running-tasks .popover-content").html(popoverHtml);
        }

        $('#btn-delete-tasks').show();

    }


    var _tasks = [];
    function getAllTasks(){
        $.get("/admin_mediaspots/get_all_tasks")
        .done(function(result){

            _tasks = result.tasks;
        });
    }

    getAllTasks();


    var websocket_dispatcher, channel;
    function initWebsocketConnection(){

        // connect to server
        websocket_dispatcher = new WebSocketRails(window.location.host + '/websocket');

        websocket_dispatcher.bind('connection_closed', function() {
            console.log('websocket connection closed. Attempting to reconect in 5 seconds');
            setTimeout(initWebsocketConnection, 5000);
        })

        channel = websocket_dispatcher.subscribe('tr069');

        channel.bind('tasks_inserts', function(tasks) {
            tasks = JSON.parse(tasks);
            var tasksToAdd = []
            _.each(tasks, function(task){
                if(!_.find(_tasks, { _id: task._id})){
                    tasksToAdd.push(task);
                }
            });

            _.each(tasksToAdd, function(t){ _tasks.push(t) });

            updateTasksPopover();
        });
        channel.bind('tasks_remove', function(task) {

            task = JSON.parse(task);

            var newTasks = _.reject(_tasks, { _id: task._id });

            if(selectedDevice != null){
                var deviceId = selectedDevice.details._id;
                var deviceLastTasks = _.filter(_tasks, function(t){return t.device == deviceId});
                var deviceNewTasks = _.filter(newTasks, function(t){return t.device == deviceId});

                if(deviceNewTasks.length == 0 && deviceLastTasks.length > 0){
                    refreshMediaspots();
                    $('#updating-loader').show();
                }
            }

            _tasks = newTasks;

            updateTasksPopover();
        });
    }


    initWebsocketConnection();


    $('[data-toggle="tooltip"]').tooltip();
});