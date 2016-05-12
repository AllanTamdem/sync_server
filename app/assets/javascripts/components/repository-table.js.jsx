var RepositoryTable = React.createClass({

  getInitialState: function() {
    return({
      files: [],
      folders:[],
      path: this.props.path,
      loading: false,
      deleting: false,
      pasting: false,
      itemsToCut: null,
      itemsToCopy: null
    });
  },

  loadFiles: function(){
    this.setState({
      loading: true
    }, function(){

      var url = this.props.files_url + "?path=" + (this.props.path_prefix||'') + this.state.path;

      url += '&bucket=' + this.props.bucket;

      $.getJSON(url)
      .done(function(response) {

        if(response.error){
          toastr.error(response.error);
          this.setState({
            files: [],
            folders: []
          });
        }
        else{
          this.setState({
            files: response.files,
            folders: response.folders
          });
        }
      }.bind(this))
      .always(function() {

        this.setState({
          loading: false
        });

      }.bind(this));


    });

  },

  componentDidMount: function() {
  	this.loadFiles();
  },

  onChangeFolder: function (new_folder, event) {
    event.preventDefault();

    var path = new_folder.full_path;

    if(this.props.path_prefix
      && path.indexOf(this.props.path_prefix) === 0){
      path = path.slice(this.props.path_prefix.length);
    }

    this.setState({
      files:[],
      folders:[],
      path: path
    }, function(){
      window.location = '#path=' + path;
      this.props.onChangePath(path);
      this.loadFiles();
    });
  },

  onTriggerCreateFolder: function(event){
    event.preventDefault();

    this.refs.create_folder.start();
  },

  onTriggerRenameFile: function(event){
    event.preventDefault();

    var checked = this.getCheckedItems();

    if(checked.files.length == 1){
      this.refs['file_' + checked.files[0].key].edit();
    }

  },

  onTriggerGetDownloadUrl: function(event){
    event.preventDefault();

    var checked = this.getCheckedItems();

    if(checked.files.length == 1){      

      var url = this.props.download_file_url + '?key=' + checked.files[0].key;
      url += '&bucket=' + this.props.bucket;

      $.get(url, function(response) {

        // the focus and selection won't work the second time
        // if the input is not unique
        var idInput = "input-download-url-" + (new Date().getTime());

        var modal = $('<div class="modal fade ">'
          +' <div class="modal-dialog bg-info">'
            +' <div class="modal-content">'
              +' <div class="modal-body">'
                + '<div class="well" style="margin:0">'
                  + '<h5>This URL is valid for one hour :</h5>'
                  + '<input id="' + idInput + '" type="text" class="form-control" value="' + response + '">'
                +' </div>'
              +' </div>'
            +' </div>'
          +' </div>'
        +'</div>').modal();

        modal.on('shown.bs.modal', function (e) {
          var input = document.getElementById(idInput);
          input.focus();
          input.setSelectionRange(0, input.value.length); 
        })

      });
    }

  },

  getCheckedItems: function(){
    return {
      files: _.where(this.state.files, {'checked': true}),
      folders: _.where(this.state.folders, {'checked': true})
    };
  },

  onTriggerDelete: function(event){
    event.preventDefault();

    var checked = this.getCheckedItems();

    var number_items = checked.files.length + checked.folders.length;

    var to_process = false;
    if(number_items > 1){
      to_process = confirm('Are you sure you want to delete these ' + number_items + ' items?');
    }
    else if(number_items == 1){
      var item = _.find(this.state.files, {'checked': true});
      if(item == null)
        item = _.find(this.state.folders, {'checked': true});

      to_process = confirm('Are you sure you want to delete ' + item.name + '?');
    }

    if(to_process == false)
      return;

    this.setState({deleting: true});

    $.post(this.props.delete_files_url, {
        bucket: this.props.bucket,
        files: _.pluck(checked.files, 'key'),
        folders: _.pluck(checked.folders, 'full_path')
      })
    .done(function(){

      this.loadFiles();

    }.bind(this))
    .complete(function(){

      this.setState({deleting: false});

    }.bind(this));

  },

  onFolderCreated: function(){
    this.loadFiles();
  },

  onFileRenamed: function(){
    this.loadFiles();
  },

  onCheckItem: function(item, item_type, event){
    event.preventDefault();
    item.checked = !item.checked;

    if(item_type == 'folder')
      this.setState({
        folders: this.state.folders
      });
    else
      this.setState({
        files: this.state.files
      });
  },

  onTriggerCut: function(){
    this.setState({
      itemsToCut: this.getCheckedItems(),
      itemsToCopy: null
    });
  },

  onTriggerCopy: function(){
    this.setState({
      itemsToCut: null,
      itemsToCopy: this.getCheckedItems()
    });
  },

  onTriggerPaste: function(event){
    event.preventDefault();

    var state_items_key = 'itemsToCut'
    var url = this.props.cut_paste_files_url

    if(this.state.itemsToCopy != null){
      state_items_key = 'itemsToCopy'
      url = this.props.copy_paste_files_url
    }

    var params = {
      bucket: this.props.bucket,
      files: _.pluck(this.state[state_items_key].files, 'key'),
      folders: _.pluck(this.state[state_items_key].folders, 'full_path'),
      destination: (this.props.path_prefix||'') + this.state.path
    };

    this.setState({
      pasting: true,
      itemsToCut: null,
      itemsToCopy: null
    });

    $.ajax({
      type: "POST",
      url: url,
      timeout: 3600000, //this is one hour. it might take a while to copy the files. 
      // but it shouldn't take more than an hour as it's copying internally (from s3 to s3)
      data: params
    })
    .done(function(response){

        if(response && response.error){
          toastr.error(response.error);
        }
        this.loadFiles();
        
      }.bind(this))
    .always(function(){

      this.setState({ pasting: false });

    }.bind(this));

    // $.post(url, params)
    // .done(function(response){

    //     if(response && response.error){
    //       toastr.error(response.error);
    //     }
    //     this.loadFiles();
        
    //   }.bind(this))
    // .always(function(){

    //   this.setState({ pasting: false });

    // }.bind(this));
  },

  render: function() {

    var folderRows = this.state.folders.map(function(folder) {

      if((this.props.path_prefix && this.state.path == '') ||
        (!this.props.path_prefix && (this.state.path.split('/').length -1) == 1) //first folder
        ){
        
        if(folder.name == '.staging'){
          folder.staging = true;
        }
        else if(folder.name == '.mediacenter'){
          folder.mediacenter = true;
        }
      }

      return (
          <RepositoryTableRowFolder
            key={folder.full_path}
            folder={folder}
            onGoIntoFolder={this.onChangeFolder.bind(this, folder)}
            onCheckItem={this.onCheckItem.bind(this, folder, 'folder')} />
        )
    }, this);

  	var fileRows = this.state.files.map(function(file) {
		  return <RepositoryTableRowFile      
        ref={"file_" + file.key}
        key={file.key}
        file={file}
        bucket={this.props.bucket}
        metadata_file={file.metadata_file || null}
        editing={!!file.rename}
        onCheckItem={this.onCheckItem.bind(this, file, 'file')}
        rename_file_url={this.props.rename_file_url}
        download_file_url={this.props.download_file_url}
        onFileRenamed={this.onFileRenamed} />
    }, this);

    var checkedItems = _.where(this.state.folders.concat(this.state.files), {'checked': true});
    var checkedFiles = _.where(this.state.files, {'checked': true});

    return (
    	<div>
        <button type="button" className="btn btn-primary btn-xs"
          onClick={this.onTriggerCreateFolder}>
          Create Folder
        </button>
        &nbsp;
        <button type="button" className="btn btn-primary btn-xs"
          disabled={checkedItems.length != 1 || checkedFiles.length != 1 }
          onClick={this.onTriggerRenameFile}>
          Rename file
        </button>
        &nbsp;
        <button type="button" className="btn btn-primary btn-xs"
          disabled={checkedItems.length != 1 || checkedFiles.length != 1 }
          onClick={this.onTriggerGetDownloadUrl}>
          Get download URL
        </button>
        &nbsp;
        <button type="button" className="btn btn-danger btn-xs"
          disabled={checkedItems.length == 0}
          onClick={this.onTriggerDelete}>
          Delete
        </button>
        {
          this.state.deleting &&          
          <span>&nbsp;<img width="20" height="20" src="/assets/loader.gif" /></span>
        }
        &nbsp;
        <button type="button" className="btn btn-primary btn-xs"
          disabled={checkedItems.length == 0}
          onClick={this.onTriggerCut}>
          Cut
        </button>
        &nbsp;
        <button type="button" className="btn btn-primary btn-xs"
          disabled={checkedItems.length == 0}
          onClick={this.onTriggerCopy}>
          Copy
        </button>
        &nbsp;
        <button type="button" className="btn btn-primary btn-xs"
          disabled={this.state.itemsToCut == null && this.state.itemsToCopy == null }
          onClick={this.onTriggerPaste}>
          Paste
        </button>
        &nbsp;
        {
          this.state.pasting &&
          <img width="20" height="20" src="/assets/loader.gif" />
        }
    		<div>
          <RepositoryTablePath
          path={this.state.path}
          onChangeFolder={this.onChangeFolder} />
        </div>
	      <table style={{marginBottom: 0}} className="table table-bordered table-hover table-condensed">
          <thead>
            <tr>
              <th style={{width: '25px', padding:'0 0 5px 2px'}}>
                {
                    this.state.loading &&
                   <img width="20" height="20" src="/assets/loader.gif" />
                }
              </th>
              <th>Name</th>
              <th style={{width: '10%'}}>Size</th>
            </tr>
          </thead>
	      	<tbody>
            <RepositoryTableRowFolderCreation
              ref="create_folder"
              path={this.state.path}
              bucket={this.props.bucket}
              create_folder_url={this.props.create_folder_url}
              onFolderCreated={this.onFolderCreated}
              path_prefix={this.props.path_prefix} />
            {folderRows}
		        {fileRows}
	      	</tbody>
	      </table>
        {
            !this.state.loading && this.state.files.length == 0 && this.state.folders.length == 0 &&
           <span>&nbsp;Emtpy folder</span>
        }
        {
       //  <br/>
       //  <br/>
       //  <br/>
       //  <br/>
       //  <pre>{JSON.stringify(this.state.files, null, 2)}</pre>
	      // <pre>{JSON.stringify(this.state.folders, null, 2)}</pre>
        }
    	</div>
    )
  }
});