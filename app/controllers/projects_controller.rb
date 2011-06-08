class ProjectsController < ApplicationController

  before_filter :user_logged

	def index
		@projects = @user_logged.projects.paginate(:page => params[:page], :per_page => 6)
  end
	
	def show
		@project = Project.find(params[:id])
    if !@user_logged.projects.include? @project
      flash[:error] = 'No tiene privilegios para ver el proyecto.'
      redirect_to root_path
    end
  end

  private
  def user_logged
    @user_logged = User.find(session[:user_id])
  end

end
