class Admin::ActivitiesController < ApplicationController

  require_role "super_user"

  before_filter :user_logged
  
  def index
    if !params[:project_id].nil?
      @project = Project.find(params[:project_id])
    end
		if @user_logged.has_role?('admin') and !@project.nil?
			@activities = @project.activities.paginate(:page => params[:page], :per_page => 6)
    elsif @user_logged.has_role?('admin')
      @activities = Activity.find(:all).paginate(:page => params[:page], :per_page => 6)
    elsif @user_logged.has_role?('super_user') and !@project.nil? and @user_logged.own_projects.include? @project
      @activities = @project.activities.paginate(:page => params[:page], :per_page => 6)
    elsif @user_logged.has_role?('super_user') and !@project.nil? and !@user_logged.own_projects.include? @project
      flash[:error] = 'No tiene privilegios para esta acción.'
      redirect_to :back
    else
			@activities = @user_logged.own_projects.map{|p| p.activities}.paginate(:page => params[:page], :per_page => 6)
		end
  end

  def show
		if correct_user(@user_logged, params[:id])
			begin
				@activity = Activity.find(params[:id])
			rescue ActiveRecord::RecordNotFound
				flash[:error]="Actividad incorrecta."
				redirect_to(:action => :index)
			end
		else
			flash[:error] = "Actividad incorrecta."
			redirect_to(:action => :index)
		end
	end

  def new
		if !params[:project_id].nil?
			@project = Project.find(params[:project_id])
		end
		if @user_logged.has_role?('admin') and @project.nil?
			@projects = Project.find(:all)
		elsif @project.nil?
			@projects = @user_logged.own_projects
			if @projects.length == 1
			end
		end
		@activity = Activity.new
  end

  def create
		@activity = Activity.new(params[:activity])
    if @activity.save
    	flash[:notice] = "La actividad #{@activity.id} ha sido creado satisfactoriamente."
      redirect_to admin_activity_path(@activity)
    else
      render :action => "new"
    end
  end

  def destroy
		@user = User.find(session[:user_id])
    @act = Activity.find(params[:id])
		if Activity.activity_include(@user, @act)
    	begin
    		@act.destroy
    		flash[:notice] ="La actividad #{@act.name} ha sido eliminado"
    	rescue Exception => e
    		flash[:error] = e.message
			end
		else
				flash[:error] = "No tiene permisos para esta acccion."
		end
    redirect_to(admin_activities_path)
  end

  private
  def user_logged
    @user_logged = User.find(session[:user_id])
  end

  protected

	# devuelve los id de todas las actividades de los proyectos de los que un usuario es
	# jefe de proyecto

	def admin_activities(user)
		activities_aux = Project.find(:all,
							:conditions => {:user_id => user.id}).collect{|x| x.activities }

		activities_aux = activities_aux.flatten.collect{|y| y.id }

		activities_aux.flatten
	end

	# Indica si un usuario es administrador, o si es jefe de proyecto y la actividad que quiere
	# ver pertenece a uno de sus proyectos.

	def correct_user(user, param)
		((user.has_role?('super_user') and admin_activities(user).include?(param.to_i)) or
			(user.has_role?('admin')))
	end

end
