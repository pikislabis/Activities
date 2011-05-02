class ProjectsController < ApplicationController

	require_role "super_user"
	require_role "admin", :only => [:destroy, :new, :mod_proj] 


	def index
		@user = User.find(session[:user_id])
		@projects = Project.paginate_user(@user, params[:page])
  end
  
	
	def new
		if User.find(session[:user_id]).has_role?("admin")
			@project = Project.new
		else
			flash[:error] = "No tiene permisos para crear proyectos."
			redirect_to(:controller => 'projects', :action => 'index')
		end
	end
	
  
	def create
		@project = Project.new(params[:project])

		if @project.save
			flash[:notice] = "El proyecto #{@project.name} ha sido creado satisfactoriamente."
		  redirect_to(:action => :index)
		else
			render :action => "new"
		end
	end

	# Muestra el proyecto selecionado y todos los usuarios que son jefes de proyecto para poder ser
	# seleccionados como tales en el proyecto
	
	def show
		@user = User.find(session[:user_id])
		@project = Project.find(params[:id])
		if @user.has_role?('admin')
			@users = User.find(:all).select { |u| u.has_role?('super_user') }
		end
		if !@project.belong_to_user(@user) and !@user.has_role?('admin')
			flash[:error] = "No tiene permisos para esta accion."
			redirect_to(:action => 'index')
			return
		end
  end
	
	# Modifica el jefe de proyecto de un proyecto

  def mod_proj
  	@project = Project.find(params[:id])
  		
  	if @project.update_attributes(params[:project])
  		flash[:notice] = "Proyecto modificado."
  	else
  		flash[:error] = "Error."
  	end
  		
  	redirect_to(:controller => 'projects', :action => 'show', :id => params[:id])
  end
	
  	
	def destroy
    @project = Project.find(params[:id])
    begin
    	@project.destroy
    	flash[:notice] = "El proyecto #{@project.name} ha sido eliminado"
    rescue Exception => e
    	flash[:error] = e.message
		end
    render :action => "index"
	end

end
