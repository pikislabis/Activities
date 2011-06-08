class TasksController < ApplicationController

  before_filter :values

  require_role "super_user", :for_all_except => [:index, :show, :edit]

  require 'related_select_form_helper'	#crear select anidados.

  def index

		@user = User.find(session[:user_id])
		# Proyectos a los que esta adscrito el usuario
		@projects = @user.projects
    if @projects.blank?
      flash[:error] = "No está asociado a ningún proyecto."
      redirect_to root_path and return false
    end

		# Si viene a traves de un enlace del root
		if (params[:id1])
			session[:current_date] = params[:id1].to_date
		else
			session[:current_date] = Date.today
		end

		@current_date = session[:current_date]

		# Dias (numero) de la semana
		@days = days_of_week(@current_date.to_date)
		@project = Project.find(session[:current_project_id])
		session[:current_activity_id] = @project.activities.first.id

		# Actividades de la semana con tareas
		@activities = Activity.this_week_with_tasks(@user, @current_date)

		# Vemos si la semana está validada
		@validated = TasksValidated.find(:first, :conditions => {:user_id => @user.id,
													:week => @current_date.to_date.strftime("%W"),
													:year => @current_date.to_date.year})
  end


  def show
    @user = User.find(session[:user_id])

    if params[:project].nil?
  			if params[:activity].nil?
    			@project = Project.find(session[:current_project_id])
    			@activity = @project.activities.first
    		else
    			@activity = Activity.find(params[:activity])
    	  	@project = @activity.project
    	  	session[:current_project_id] = @project.id
    	  	session[:current_activity_id] = @activity.id
  			end
  	else
  			@project = Project.find(params[:project])
  			@activity = @project.activities.first
  			session[:current_project_id] = @project.id
  			session[:current_activity_id] = @activity.id
  	end

		# Actividades con tareas ejecutadas

		@activities = Activity.get_activities_tasks(@user, @current_date)

		@days = days_of_week(@current_date.to_date)

		# Mostrará si la semana seleccionada está validada
		@validated = TasksValidated.find(:first, :conditions => {:user_id => session[:user_id],
															 :week => session[:current_date].to_date.strftime("%W"),
															 :year => session[:current_date].to_date.year})
		render(:layout => false)
  end


  def edit
		@user = User.find(session[:user_id])
		if (params[:current_date].nil? and session[:current_date].nil?)
			session[:current_date] = Date.today
		else
			if !params[:current_date].nil?
				session[:current_date] = params[:current_date]
				@hide = 1
			end
		end
		@current_date = session[:current_date]

		if params[:id] == "remote_function"
			@hide = 0
			if params[:activity].nil?
				if session[:current_activity_id].nil?
					@project = Project.find(session[:current_project_id])
					@activity = @project.activities.first
				else
					@activity = Activity.find(session[:current_activity_id])
					@project = @activity.project
				end
			else
				@activity = Activity.find(params[:activity])
				@project = @activity.project
			end
		else
  		if params[:project].nil?
  			if params[:activity].nil?
    			@project = Project.find(session[:current_project_id])
    			@activity = @project.activities.first
    		else
    			@activity = Activity.find(params[:activity])
    	  	@project = @activity.project
    	  	session[:current_project_id] = @project.id
    	  	session[:current_activity_id] = @activity.id
  			end
  		else
  			@project = Project.find(params[:project])
  			@activity = @project.activities.first
  			session[:current_project_id] = @project.id
  			session[:current_activity_id] = @activity.id
  		end
		end

		# Actividades con tareas ejecutadas

		@activities = Activity.get_activities_tasks(@user, @current_date)

		@days = days_of_week(@current_date.to_date)

		# Mostrará si la semana seleccionada está validada
		@validated = TasksValidated.find(:first, :conditions => {:user_id => session[:user_id],
															 :week => session[:current_date].to_date.strftime("%W"),
															 :year => session[:current_date].to_date.year})
		render(:layout => false)
	end

  private

    def values
		@freq_type = ["Una vez", "Diaria", "Semanal", "Mensual"]
		@frequencies = [['Una vez', 0], ['Diaria', 1], ['Semanal', 2], ['Mensual', 3]]
	end

end
