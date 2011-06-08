class Admin::ProjectsController < ApplicationController

  require_role "super_user"
	require_role "admin", :only => [:destroy, :new, :mod_proj, :create]

  before_filter :user_logged

  def index
		if !params[:user_id].blank?
      @projects = User.find(params[:user_id]).projects.paginate(:page => params[:page], :per_page => 6)
    else
      @projects = Project.find(:all).paginate(:page => params[:page], :per_page => 6)
    end
  end

  def new
		@project = Project.new
    @users = User.find(:all).select{|u| u.has_role?('super_user')}
  end

  def create
		@project = Project.new(params[:project])

		if @project.save
			flash[:notice] = "El proyecto #{@project.name} ha sido creado satisfactoriamente."
		  redirect_to admin_projects_path
		else
			render :action => "new"
		end
  end

  def show
		@user = User.find(session[:user_id])
		@project = Project.find(params[:id])
		if @user.has_role?('admin')
			@users = User.find(:all).select { |u| u.has_role?('super_user') }
		end
		if !@project.belong_to_user(@user) and !@user.has_role?('admin')
			flash[:error] = "No tiene permisos para esta acción."
			redirect_to(:action => 'index')
			return
		end
  end

  def destroy
    @project = Project.find(params[:id])
    begin
    	@project.destroy
    	flash[:notice] = "El proyecto #{@project.name} ha sido eliminado"
    rescue Exception => e
    	flash[:error] = e.message
		end
    redirect_to admin_projects_path
  end

  def mod_proj
  	@project = Project.find(params[:id])

  	if @project.update_attributes(params[:project])
  		flash[:notice] = "Proyecto modificado."
  	else
  		flash[:error] = "Error."
  	end

  	redirect_to admin_project_path(@project)
  end

  private
  def user_logged
    @user_logged = User.find(session[:user_id])
  end

end
