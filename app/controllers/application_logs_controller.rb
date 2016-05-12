class ApplicationLogsController < ApplicationController
  before_action do
    unless current_user.try(:admin?)
      redirect_to root_path
    end
  end


  def index

  	@logs = ApplicationLog.order_by(['time', 'desc']).paginate(:page => params[:page], :per_page => 30)

  end


end