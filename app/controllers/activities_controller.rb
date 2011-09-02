class ActivitiesController < ApplicationController

  before_filter :user_logged

  def index
		@activities = @user_logged.activities.paginate(:page => params[:page], :per_page => 6)
  end
  
  def show
		@activity = Activity.find(params[:id])
		if !(@user_logged.activities.include? @activity)
		  flash[:error] = 'No tiene privilegios para ver la actividad.'
		  redirect_to root_path
		end
  end

	protected

    def user_logged
      @user_logged = User.find(session[:user_id])
    end

end
