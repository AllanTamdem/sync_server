RepositoryTableRowFile = React.createClass({

  constants: {
    ESCAPE_KEY: 27,
    ENTER_KEY: 13
  },

  extension_icon: {
    pdf: 'fa-file-pdf-o',
    mp4: 'fa-file-video-o',
    avi: 'fa-file-video-o',
    mpg: 'fa-file-video-o',
    wmv: 'fa-file-video-o',
    '3gp': 'fa-file-video-o',
    m4v: 'fa-file-video-o',
    mov: 'fa-file-video-o',
    zip: 'fa-file-archive-o',
    tar: 'fa-file-archive-o',
    rar: 'fa-file-archive-o',
    '7z': 'fa-file-archive-o',
    gz: 'fa-file-archive-o',
    mp3: 'fa-file-audio-o',
    wav: 'fa-file-audio-o',
    jpg: 'fa-file-image-o',
    bmp: 'fa-file-image-o',
    gif: 'fa-file-image-o',
    png: 'fa-file-image-o',
    tif: 'fa-file-image-o',
    txt: 'fa-file-text-o'
  },

  getInitialState: function() {
    return({
      editing: false,
      file_name: this.props.file.name,
      metadata_file: this.props.metadata_file,
      edited: false,
      loading: false
    });
  },

  componentDidMount: function(){
    pubsub.subscribe("metadata-saved-" + this.props.file.key + '.json', function(){
      if(!this.state.metadata_file){
        this.setState({
          metadata_file: {key: this.props.file.key + '.json'}
        })
      }
    }.bind(this));

    pubsub.subscribe("metadata-deleted-" + this.props.file.key + '.json', function(){
      if(this.state.metadata_file){
        this.setState({
          metadata_file: null
        })
      }
    }.bind(this));
  },

  componentWillUnmount: function(){
    pubsub.unsubscribe("metadata-saved-" + this.props.file.name + '.json');
    pubsub.unsubscribe("metadata-deleted-" + this.props.file.name + '.json');
  },

  edit: function(){
    this.setState({
      editing: true,
      file_name: this.props.file.name,
      edited: false
    });
  },

  componentDidUpdate: function (prevProps, prevState) {
    if (!prevState.editing && this.state.editing) {
      var node = React.findDOMNode(this.refs.editField);
      node.focus();
      node.setSelectionRange(0, node.value.length);
    }
  },


  handleChange: function(event){
    this.setState({
      file_name: event.target.value,
      edited: true
    });
  },

  renameFile: function(file_name){
    this.setState({
      loading: true,
      file_name: file_name,
      editing: false,
      edited: false
    }, function(){

      var old_key = this.props.file.key;
      var new_key = file_name;

      var indexLastSlash = old_key.lastIndexOf('/');
      if(indexLastSlash > -1){
        new_key = old_key.substr(0, indexLastSlash+1) +  file_name
      }

      var old_file_name = old_key.substr(indexLastSlash + 1);

      $.post(this.props.rename_file_url, {
          bucket: this.props.bucket,
          old_key: old_key,
          new_key: new_key
        })
      .done(function(response){          

          if(response && response.error){
            toastr.error(response.error);
            this.setState({
              file_name: old_file_name
            });
          }
          else{
            this.props.onFileRenamed();
          }

        }.bind(this))
      .always(function(){
        this.setState({
          loading: false
        });
      }.bind(this));

    });
  },

  handleSubmit: function (event) {    
    this.setState({editing: false});

    if(this.state.edited == false){
      return;
    }

    var file_name = this.state.file_name.trim();

    if(file_name){
      this.renameFile(file_name);
    }
  },

  handleKeyDown: function (event) {
    if (event.which === this.constants.ESCAPE_KEY) {
      this.setState({editing: false});
    } else if (event.which === this.constants.ENTER_KEY) {
      this.handleSubmit(event);
    }
  },

  handleDownload: function (event) {
    event.preventDefault();

    var url = this.props.download_file_url + '?key=' + this.props.file.key;

    url += '&bucket=' + this.props.bucket;

    $.get(url, function(response) {

      var link = document.createElement('a');
      link.href = response;
      link.tarket = '_blank';
      document.body.appendChild(link);
      link.click();

    });
  },


  editMetadata: function (event) {
    event.preventDefault();

    var file = this.props.file;

    var createOptions;

    if(!this.state.metadata_file){
      createOptions = {
        size : file.size
      }
    }

    EditMetadata.showFromTable(file.name, file.key, this.state.metadata_file, createOptions);
  },

  render: function() {

    var checked_icon = this.props.file.checked ? 'fa-check-square-o': 'fa-square-o';

    var metadata_btn;

    if(this.state.metadata_file){
      metadata_btn = (<a onClick={this.editMetadata} className="btn-metadata btn btn-info btn-minier">Edit metadata</a>)
    }
    else{
      metadata_btn = (<a onClick={this.editMetadata} className="btn-metadata btn btn-primary btn-minier">Create metadata</a>)
    }

    var file_icon = 'fa-file-o';

    var extension_index = this.state.file_name.lastIndexOf('.');

    if(extension_index > -1){
      var extension = this.state.file_name.substr(extension_index+1);
      if(this.extension_icon[extension])
        file_icon = this.extension_icon[extension];
    }

    if(this.extension_icon)

    var cell;
    if(this.state.editing){
      cell = (
          <span>
            <i className={'fa ' + file_icon}></i>
            &nbsp;
            <input ref="editField" className="form-control input-sm"
            value={this.state.file_name}
            onChange={this.handleChange}
            onBlur={this.handleSubmit}
            onKeyDown={this.handleKeyDown} />
          </span>
        )
    }
    else{
      cell = (
          <span>
            <i onClick={this.handleDownload} className={'pointer fa ' + file_icon}></i>
            &nbsp;
            <span onClick={this.handleDownload} className="pointer hover-underline" >{this.state.file_name}</span>
            {
              this.state.loading &&
              <span>&nbsp;<img width="20" height="20" src="/assets/loader.gif" /></span>
            }
          </span>
        )
    }

  	return (
  		<tr className="file-row" >
        <td onClick={this.props.onCheckItem} ><i className={"pointer fa " + checked_icon}></i></td>
  			<td>
  				{cell}
          &nbsp;
          {
            !_.endsWith(this.state.file_name, '.json') &&
            metadata_btn
          }
  			</td>        
        <td>
          {this.props.file.size_pretty}
        </td>
  		</tr>
  	);
  }

})