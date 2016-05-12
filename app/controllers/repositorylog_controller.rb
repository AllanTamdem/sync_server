class RepositorylogController < ApplicationController
  before_action do
    unless current_user.try(:admin?)
      redirect_to root_path
    end
  end

  helper_method :sort_column, :sort_direction


  def index

    @logs = Log.search(params[:search]).order(sort_column + ' ' + sort_direction).page(params[:page]).per_page(30)
  	
  end



  def get

    render :json => Log.find(params[:id])
    
  end


  private
  
  def sort_column
    Log.column_names.include?(params[:sort]) ? params[:sort] : "id"
  end
  
  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end

end