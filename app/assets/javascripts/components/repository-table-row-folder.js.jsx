var RepositoryTableRowFolder = React.createClass({

  render: function() {

  	// var styleRow = { cursor: 'pointer' };
  	// var styleText = { textDecoration: 'underline'};

    var icon = this.props.folder.checked ? 'fa-check-square-o': 'fa-square-o';

    var colorStaging = 'blue'
    var colorMediacenter = 'orange'

    var iconClass = 'pointer fa fa-folder';

    if(this.props.folder.staging){
      iconClass += ' ' + colorStaging;
    }
    else if(this.props.folder.mediacenter){
      iconClass += ' ' + colorMediacenter;
    }

  	return (
      <tr className="folder-row" >
        <td onClick={this.props.onCheckItem}><i className={"pointer fa " + icon}></i></td>
  			<td>
  				<i onClick={this.props.onGoIntoFolder} className={iconClass}></i>&nbsp;
  				<span onClick={this.props.onGoIntoFolder} className="pointer hover-underline" >{this.props.folder.name}</span>
          &nbsp;
          &nbsp;
          {
            this.props.folder.staging &&
            <span className="info-folder">
              <i className={"fa fa-info-circle " + colorStaging}></i>&nbsp;
              <small>files in this directory are not synced with mediaspots</small>
            </span>
          }
          {
            this.props.folder.mediacenter &&
            <span className="info-folder">
              <i className={"fa fa-info-circle " + colorMediacenter}></i>&nbsp;
              <small>files in this directory are only synced with mediacenters</small>
            </span>
          }
         
  			</td>
        <td></td>
  		</tr>
  	);
  }

})